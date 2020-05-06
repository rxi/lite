#!/usr/bin/python2.7
import os, sys, platform, shutil
import re, threading, time, json
from os import path
from hashlib import sha1
from multiprocessing import cpu_count


config_file = "build.config.py"
cache_dir = ".buildcache"
object_dir = path.join(cache_dir, "obj")
cache_file = path.join(cache_dir, "cache.json")
max_workers = cpu_count()


config = {
    "compiler" : "gcc",
    "output"   : "a.out",
    "source"   : [ "src" ],
    "include"  : [],
    "cflags"   : [],
    "lflags"   : [],
    "run"      : "./{output}"
}


Hint, Warn, Error = range(3)
log_prefix = {
    Hint: "\x1b[32mHint:\x1b[0m",
    Warn: "\x1b[33mWarn:\x1b[0m",
    Error: "\x1b[31;1mError:\x1b[0m"
}


log_lock = threading.Lock()

def log(msg, mode=Hint):
    log_lock.acquire()
    print log_prefix[mode], msg
    sys.stdout.flush()
    log_lock.release()


def error(msg):
    log(msg, mode=Error)
    os._exit(1)


def load_config(filename):
    """ loads the given config file into the `config` global dict """
    if not path.exists(filename):
        error("config file does not exist: '%s'" % filename)

    d = {
        "opt": sys.argv,
        "platform": platform.system(),
        "error": error,
        "log": log,
        "Hint": Hint,
        "Warn": Warn,
        "Error": Error
    }
    execfile(filename, d)
    config.update(d)

    if len(config["source"]) == 0:
        error("no source directories specified in config")


def load_cache(cache_file):
    if not path.exists(cache_file):
        return { "hashes": [], "cmd": "" }
    with open(cache_file) as fp:
        log("loaded cache")
        return json.load(fp)


def update_cache(cache_file, obj):
    with open(cache_file, "wb") as fp:
        json.dump(obj, fp, indent=2)
    log("updated cache")


def resolve_file(filename, dir):
    """ finds the actual location of an included file """
    f = path.join(dir, filename)
    if path.exists(f):
        return short_name(f)

    for dir in config["include"]:
        f = path.join(dir, filename)
        if path.exists(f):
            return short_name(f)


file_info_cache = {}

def get_file_info(filename):
    """ returns a dict of file info for the given file """
    if filename in file_info_cache:
        return file_info_cache[filename]

    hash = sha1()
    includes = []

    with open(filename) as fp:
        for line in fp.readlines():
            # get includes
            if "#include" in line:
                match = re.match('^\s*#include\s+"(.*?)"', line)
                if match:
                    includes.append( match.group(1) )
            # update hash
            hash.update(line)
            hash.update("\n")

    res = { "hash": hash.hexdigest(), "includes": includes }
    file_info_cache[filename] = res
    return res


def short_name(filename):
    """ returns the filename relative to the current path """
    n = len(path.abspath("."))
    return path.abspath(filename)[n+1:]


def get_deep_hash(filename):
    """ creates a hash from the file and all its includes """
    h = sha1()
    processed = set()
    files = [ resolve_file(filename, ".") ]

    while len(files) > 0:
        f = files.pop()
        info = get_file_info(f)
        processed.add(f)

        # update hash
        h.update(info["hash"])

        # add includes
        for x in info["includes"]:
            resolved = resolve_file(x, path.dirname(f))
            if resolved:
                if resolved not in processed:
                    files.append(resolved)
            else:
                log("could not resolve file '%s'" % x, mode=Warn)

    return h.hexdigest()


def build_deep_hash_dict(cfiles):
    """ returns a dict mapping each cfile to its hash """
    res = {}
    for f in cfiles:
        res[f] = get_deep_hash(f)
    return res


def get_cfiles():
    """ returns all .h and .c files in source directories """
    res = []
    for dir in config["source"]:
        for root, dirs, files in os.walk(dir):
            for file in files:
                if file.endswith((".c", ".h")):
                    f = path.join(root, file)
                    res.append( short_name(f) )
    return res


def build_compile_cmd():
    """ creates the command used to compile files """
    lst = [
        config["compiler"],
        " ".join(map(lambda x: "-I" + x, config["include"])),
        " ".join(config["cflags"]),
        "-c", "{infile}", "-o", "{outfile}"
    ]
    return " ".join(lst)


def obj_name(filename):
    """ creates the object file name for a given filename """
    filename = re.sub("[^\w]+", "_", filename)
    return filename[:-2] + "_" + sha1(filename).hexdigest()[:8] + ".o"


def compile(cmd, filename):
    """ compiles the given file into an object file using the cmd """
    log("compiling '%s'" % filename)

    outfile = path.join(object_dir, obj_name(filename))

    res = os.system(cmd.format(infile=filename, outfile=outfile))
    if res != 0:
        error("failed to compile '%s'" % filename)


def link():
    """ links objects and outputs the final binary """
    log("linking")
    lst = [
        config["compiler"],
        "-o", config["output"],
        path.join(object_dir, "*"),
        " ".join(config["lflags"])
    ]
    cmd = " ".join(lst)
    res = os.system(cmd)
    if res != 0:
        error("failed to link")


def parallel(func, workers=4):
    """ runs func on multiple threads and waits for them all to finish """
    threads = []
    for i in range(workers):
        t = threading.Thread(target=func)
        threads.append(t)
        t.start()
    for t in threads:
        t.join()



if __name__ == "__main__":

    start_time = time.time()

    load_config(config_file)
    run_at_exit = False
    output_dir =  path.join(".", path.dirname(config["output"]))
    cache = load_cache(cache_file)
    cmd = build_compile_cmd()

    if "run" in sys.argv:
        run_at_exit = True

    if cache["cmd"] != cmd:
        sys.argv.append("clean")

    if "clean" in sys.argv:
        log("performing clean build")
        shutil.rmtree(cache_dir, ignore_errors=True)
        cache = load_cache(cache_file)


    if not path.exists(object_dir):
        os.makedirs(object_dir)

    if not path.exists(output_dir):
        os.makedirs(output_dir)


    if "pre" in config:
        config["pre"]()


    cfiles = get_cfiles()
    hashes = build_deep_hash_dict(cfiles)


    # delete object files for cfiles that no longer exist
    obj_files = set(map(obj_name, cfiles))
    for f in os.listdir(object_dir):
        if f not in obj_files:
            os.remove(path.join(object_dir, f))


    # build list of all .c files that need compiling
    pending = []
    for f in cfiles:
        if f.endswith(".c"):
            if f not in cache["hashes"] or cache["hashes"][f] != hashes[f]:
                pending.append(f)


    # compile files until there are none left
    def worker():
        while True:
            try:
                f = pending.pop()
            except:
                break
            compile(cmd, f)


    parallel(worker, workers=max_workers)


    link()
    update_cache(cache_file, { "hashes": hashes, "cmd": cmd })

    if "post" in config:
        config["post"]()


    log("done [%.2fs]" % (time.time() - start_time))


    if run_at_exit:
        log("running")
        cmd = config["run"].format(output=config["output"])
        os.system(cmd)
