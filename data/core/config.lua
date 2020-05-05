local config = {}

config.project_scan_rate = 5
config.fps = 60
config.max_log_items = 80
config.message_timeout = 3
config.mouse_wheel_scroll = 50
config.file_size_limit = 10
config.symbol_pattern = "[%a_][%w_]*"
config.non_word_chars = " \t\n/\\()\"':,.;<>~!@#$%^&*|+=[]{}`?-"
config.treeview_size = 200 * SCALE
config.undo_merge_timeout = 0.3
config.max_undos = 10000
config.highlight_current_line = true
config.line_height = 1.2
config.indent_size = 2
config.tab_type = "soft"
config.line_limit = 80

return config
