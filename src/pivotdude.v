// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import flag

fn main()
{
	mut fp := flag.new_flag_parser(os.args)
    fp.application('pivotdude')
    fp.version('v0.0.1\nCopyright (c) 2022 jeffrey -at- ieee.org. All rights \
	reserved.\nUse of this source code (/program) is governed by an MIT \
	license,\nthat can be found in the LICENSE file.')
    fp.description('\nPivot input data on specific column combination.\n\
	Note that columns are 0-index based.')
    fp.skip_executable()
    pivot_column_arg := fp.string('pivot', `p`, "", 
								'Comma-separated list of pivot indexes.')
	value_column := fp.int('value', `v`, -1, 
								'Column of values to extract.')
	header_column := fp.int('header', `h`, -1, 
								'Column to generate header from.')
	has_header := fp.bool('no-header', `n`, true, 
								'Indicate input file has no header.')
	file_in := fp.string('file-in', `f`, "", 
								'Input file to pivot.')

	additional_args := fp.finalize() or {
        eprintln(err)
        println(fp.usage())
        return
    }

	if pivot_column_arg.len==0 || value_column==-1 || header_column==-1 ||
		file_in.len==0
	{
        println(fp.usage())
        return
	}

    additional_args.join_lines()

	pivot_column := pivot_column_arg.split(",")

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