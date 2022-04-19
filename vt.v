module main

import os
import regex
import json

const (
	help_text = '
Usage: t [options] [args]
Options:
   none		Add or check a task
   del		Delete a task
   help              
'
)

struct Json {
mut:
	tasks []Task
}

struct Task {
mut:
	content string
	checked bool
}

fn check_regex(text string, query string) bool {
	mut re := regex.regex_opt(query) or { panic(err) }
	start, end := re.match_string(text)

	if start > end {
		return false
	}
	if start == 0 {
		return true
	}
	return false
}

fn numbers(text string) bool {
	return check_regex(text, r'^[0-9\s+]*$')
}

fn range(text string) bool {
	return check_regex(text, r'^(\d+)(\s+)?-(\s+)?(\d+)$')
}

fn get_nums(text string) []u16 {
	if range(text) {
		range := text.split('-')
		start, end := range[0].u16() - 1, range[1].u16()
		mut nums := []u16{}
		for i in start .. end {
			nums << i
		}
		return nums
	} else if numbers(text) {
		mut nums := []u16{}
		for num in text.split(' ') {
			nums << num.u16() - 1
		}
		return nums
	}

	return []
}

fn main() {
	args := os.args.clone()

	if 'help' in args || '--help' in args {
		println(help_text)
		return
	}

	lines := os.read_lines('vt.json') or { [] }
	mut j := json.decode(Json, lines.join('\n')) or { Json{} }

	if args.len > 1 {
		text := args[1..].join(' ')
		no_arg_text := args[2..].join(' ')
		match args[1] {
			'del' {
				nums := get_nums(no_arg_text)
				for num in nums {
					j.tasks.delete(num)
				}
				println(nums)
			}
			else {
				nums := get_nums(text)
				if nums.len == 0 {
					// add task
					j.tasks << [Task{text, false}]
				} else if j.tasks.len != 0 {
					// check tasks
					for num in nums {
						j.tasks[num].checked = !j.tasks[num].checked
					}
				}
			}
		}
	}

	mut i := 1

	for task in j.tasks {
		print(i)
		if task.checked {
			print('. [x]')
		} else {
			print('. [ ]')
		}
		println(' $task.content')
		i++
	}

	encode := json.encode_pretty(j)
	os.write_file('vt.json', encode) ?
}
