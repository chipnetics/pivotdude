// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os

const (
	usage = 'Usage: pivotdude [SHORT-OPTION]... [STRING]...
or: pivotdude LONG-OPTION

Pivot input data on specific column combination.
Note that columns are 0-index based.

  -p (required)         comma-separated list of pivot indexes
  -h (required)         column to generate header from
  -v (required)         column of values to extract
  -f (required)         the input file to pivot
  -nh                   indicate input file has no header
     --help             display this help and exit
     --about            author and licence information
     --version          output version information and exit'

	version = 'pivotdude 0.0.1'

	about = "Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
Use of this source code (/program) is governed by an MIT license,
that can be found in the LICENSE file."
)

fn main()
{
	mut file_in := ""

	mut pivot_column := []string{}
	mut value_column := -1
	mut header_column := -1
	mut has_header := true

	mut idx := 1
	if os.args.len ==1
	{
		println(usage)
		exit(0)
	}
	for idx < os.args.len
	{
		match os.args[idx] {
			"--help" {
				println(usage)
				exit(0)
			}
			"--version" {
				println(version)
				exit(0)
			}
			"--about" {
				println(about)
				exit(0)
			}
			"-f" {
				file_in = os.args[idx+1]
			}
			"-p" {
				pivot_column = os.args[idx+1].split(",")
			}
			"-h" {
				header_column = os.args[idx+1].int()
			}
			"-v" {
				value_column = os.args[idx+1].int()
			}
			"-nh" {
				has_header = false
			}
			else
			{
			}
		}
		idx++
	}

	// CLI Error checks
	if value_column == -1 {
		eprintln("Must specify -v flag. See --help for details.")
		exit(0)
	}
	else if pivot_column.len == 0 {
		eprintln("Must specify -p flag. See --help for details.")
		exit(0)
	}
	else if header_column == -1 {
		eprintln("Must specify -h flag. See --help for details.")
		exit(0)
	}
	else if file_in.len == 0 {
		eprintln("Must specify -f flag. See --help for details.")
		exit(0)
	}
	
	lines := os.read_lines(file_in) or {panic(err)}

	mut data_array := []Data{}
	mut data_struct := Data{}

	mut delimited_header := []string{}

	for index,line in lines
	{
		if index==0 && has_header
		{
			delimited_header = line.split("\t")
			continue
		}

		delimited_row := line.split("\t")
		mut pivot_col_string := ""

		for cols in pivot_column
		{
			pivot_col_string += delimited_row[cols.int()] + "\t"
		}

		data_struct.pivot_col = pivot_col_string.all_before_last("\t")
		data_struct.value = delimited_row[value_column]
		data_struct.header_elem = delimited_row[header_column]

		data_array << data_struct
	}

	mut pivot_row := Pivot_row{}

	for value in data_array
	{
		mut ret_header := pivot_row.row[value.pivot_col] 
		ret_header.header[value.header_elem] = value.value
		pivot_row.row[value.pivot_col] = ret_header // Critical to assign back.
	}

	header_arr := get_headers(data_array)

	// Print out the header
	if !has_header // Source data does not have header; make one...
	{
		for index,value in pivot_column
		{
			print("column_$value")
			if index != pivot_column.len-1
			{
				print("\t") // more elements...
			}
		}
	}
	else // has header
	{
		for index,cols in pivot_column
		{
			print("${delimited_header[cols.int()]}")
			if index != pivot_column.len-1
			{
				print("\t") // more elements...
			}
		}
	}
	for header in header_arr
	{
		print("\t$header")
	}
	
	// Print out the pivotted values
	for key,value in pivot_row.row
	{
		print("\n")
		print("$key")
		mkeys := (&value.header).keys()

		for key0 in header_arr
		{
			if mkeys.contains(key0)
			{
				print("\t${value.header[key0]}")
			}
			else
			{
				print("\t") // Tab over missing value
			}
		}
		
	}
	
}

struct Pivot_row
{
	mut:
		row map[string]Pivot_header // Column is mapped to proper col
}

struct Pivot_header
{
	mut:
		header map[string]string
}

struct Data
{
	mut:
		header_elem string
		pivot_col string
		value string
}

fn get_headers(data_struct_array []Data) []string
{
	mut ret_string := []string{}

	for entry in data_struct_array
	{
		if !ret_string.contains(entry.header_elem)
		{
			ret_string << entry.header_elem
		}
	}
	return ret_string
}