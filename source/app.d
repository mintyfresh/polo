
import std.algorithm;
import std.conv;
import std.getopt;
import std.range;
import std.regex;
import std.stdio;
import std.string;

import markov;

struct Options
{
	string[] _inputs;
	string _output;

	size_t _length;
	size_t[] _tuples;

	string[] _seeds;
	string _filter;

	@property
	File[] inputs()
	{
		if(_inputs.length > 0)
		{
			return _inputs.map!(i => File(i, "r")).array;
		}
		else
		{
			return [ stdin ];
		}
	}

	@property
	File output()
	{
		return _output.length ? File(_output, "w") : stdout;
	}

	@property
	size_t length()
	{
		return _length;
	}

	@property
	size_t[] tuples()
	{
		if(_tuples.length > 0)
		{
			return _tuples;
		}
		else
		{
			return [ 1, 2, 3 ];
		}
	}

	@property
	string[] seeds()
	{
		return _seeds;
	}

	@property
	string filter()
	{
		return _filter;
	}
}

string[] tokens(File file, string pattern)
{
	return file
		.byLine
		.map!text
		.map!strip
		.map!splitter
		.joiner
		.filter!"a.length > 0"
		.filter!(token =>
			pattern.length ?
			token.matchFirst(pattern).empty :
			true
		)
		.array;
}

string[] tokens(string input, string pattern)
{
	return input
		.strip
		.splitter
		.filter!"a.length > 0"
		.filter!(token =>
			pattern.length ?
			token.matchFirst(pattern).empty :
			true
		)
		.array;
}

File getOutputFile(string name)
{
	return name.length ? File(name, "w") : stdout;
}

File[] getInputFiles(string[] names)
{
	if(names.length > 0)
	{
		return names.map!(n => File(n, "r")).array;
	}
	else
	{
		return [ stdin ];
	}
}

void showHelp()
{
	writeln("Usage: polo [-fhilost] -- ");
	writeln;
	writeln("Option   Long Option            Meaning");
	writeln(" -f       --filter=<pattern>     Regex filter applied to tokens");
	writeln(" -h       --help                 Show this message");
	writeln(" -i       --input=<file>         Adds an input file");
	writeln(" -l       --length=<#words>      Sets the output length in words");
	writeln(" -o       --output=<file>        Sets the output file");
	writeln(" -s       --seed=<text>          Adds a seed text");
	writeln(" -t       --tuple=<#size>        Adds a markov state tuple");
	writeln;
}

void polo(Options options)
{
	File output = options.output;
	auto chain = new MarkovChain!string(options.tuples);
	options.seeds.map!(s => s.tokens(options.filter)).each!(seed => chain.seed(seed));
	options.inputs.map!(s => s.tokens(options.filter)).each!(input => chain.train(input));

	foreach(i; 0 .. options.length)
	{
		output.write(chain.generate);

		if(i < options.length - 1)
		{
			output.write(" ");
		}
	}

	output.writeln;
}

void main(string[] args)
{
	try
	{
		bool help;
		Options options;

		args.getopt(
			config.bundling,
			"help|h",      &help,
			"filter|f",    &options._filter,
			"input|i",     &options._inputs,
			"length|l",    &options._length,
			"output|o",    &options._output,
			"seeds|s",     &options._seeds,
			"tuple|t",     &options._tuples
		);

		if(help)
		{
			showHelp;
		}
		else
		{
			polo(options);
		}
	}
	catch(Exception e)
	{
		stderr.write("Error: ");
		stderr.writeln(e.msg);
	}
}
