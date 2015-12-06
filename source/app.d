
import core.stdc.stdlib;

import std.algorithm;
import std.array;
import std.conv;
import std.getopt;
import std.random;
import std.stdio;
import std.string;
import std.typecons;

struct Options
{
	string[] _inputs;
	string _output;

	size_t _length;
	size_t[] _tuples;

	string[] _seeds;

	@property
	File[] inputs()
	{
		return _inputs.length ? _inputs.map!(i => File(i, "r")).array : [ stdin ];
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
		return _tuples.length ? _tuples : [ 1UL, 2UL, 3UL ];
	}

	@property
	string[] seeds()
	{
		return _seeds;
	}
}

struct MarkovKey
{
private:
	const size_t _size;
	const string[] _key;

public:
	this(size_t size, string[] key)
	{
		assert(key.length == size);

		_size = size;
		_key = key;
	}

	@property
	size_t size()
	{
		return _size;
	}

	bool opEquals(ref const MarkovKey other) const
	{
		return _size == other._size && _key == other._key;
	}

	bool opEquals(string[] other)
	{
		return _key == other;
	}

	string opIndex(size_t index)
	{
		return _key[index];
	}
}

class MarkovCounter
{
private:
	Nullable!size_t _total;
	size_t[string] _counters;

public:
	this(string value)
	{
		poke(value);
	}

	size_t count(string follow)
	{
		auto ptr = follow in _counters;
		return ptr ? *ptr : 0;
	}

	@property
	size_t length()
	{
		return _counters.length;
	}

	void poke(string follow)
	{
		_total.nullify;
		auto ptr = follow in _counters;

		if(ptr !is null)
		{
			(*ptr)++;
		}
		else
		{
			_counters[follow] = 1;
		}
	}

	string random()
	{
		if(length == 0)
		{
			return null;
		}
		else
		{
			size_t i = uniform(0, length);
			return _counters.keys[i];
		}
	}

	string select()
	{
		if(length == 0)
		{
			return null;
		}
		else
		{
			size_t r = uniform(0, total);

			foreach(key, value; _counters)
			{
				if(r < value)
				{
					return key;
				}
				else
				{
					r -= value;
				}
			}

			assert(0);
		}
	}

	@property
	size_t total()
	{
		if(_total.isNull)
		{
			_total = _counters.values.sum;
		}

		return _total.get;
	}
}

class MarkovState
{
private:
	size_t _size;
	MarkovCounter[MarkovKey] _state;

public:
	this(size_t size)
	{
		_size = size;
	}

	size_t count(string[] first, string follow)
	{
		auto key = MarkovKey(_size, first);
		auto ptr = key in _state;

		return ptr ? ptr.count(follow) : 0;
	}

	@property
	size_t length()
	{
		return _state.length;
	}

	void poke(string[] first, string follow)
	{
		auto key = MarkovKey(_size, first);
		auto ptr = key in _state;

		if(ptr !is null)
		{
			ptr.poke(follow);
		}
		else
		{
			_state[key] = new MarkovCounter(follow);
		}
	}

	string random()
	{
		if(length == 0)
		{
			return null;
		}
		else
		{
			size_t i = uniform(0, length);
			return _state.values[i].random;
		}
	}

	string select(string[] first)
	{
		if(length == 0)
		{
			return null;
		}
		else
		{
			auto key = MarkovKey(_size, first);
			auto ptr = key in _state;

			return ptr ? ptr.select : null;
		}
	}

	@property
	size_t size()
	{
		return _size;
	}
}

class MarkovChain
{
private:
	string[] _history;
	MarkovState[size_t] _states;

public:
	this(size_t[] sizes...)
	{
		_history.length = sizes.reduce!max;

		foreach(size; sizes)
		{
			_states[size] = new MarkovState(size);
		}
	}

	string generate()
	{
		string result = null;
		auto states = _states.values.sort!"a.size > b.size";

		foreach(state; states)
		{
			string[] key = _history[$ - state.size .. $];
			result = state.select(key);
			if(result) break;
		}

		if(result is null)
		{
			foreach(state; states)
			{
				result = state.random;
				if(result) break;
			}
		}

		if(result is null)
		{
			assert(0);
		}

		return push(result);
	}

	string push(string token)
	{
		copy(_history[1 .. $], _history[0 .. $ - 1]);
		return _history[$ - 1] = token;
	}

	@property
	void seed(string[] seed)
	{
		foreach(token; seed)
		{
			push(token);
		}
	}

	void train(string[] input)
	{
		foreach(index, value; input)
		{
			foreach(state; _states)
			{
				if(index >= state.size)
				{
					string[] key = input[index - state.size .. index];
					state.poke(key, value);
				}
			}
		}
	}
}

string[] tokens(File file)
{
	return file
		.byLine
		.map!text
		.map!strip
		.map!splitter
		.joiner
		.filter!"a.length > 0"
		.array;
}

string[] tokens(string input)
{
	return input
		.strip
		.splitter
		.filter!"a.length > 0"
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
	writeln("Usage: polo [-hilost] -- ");
	writeln;
	writeln("Option   Long Option            Meaning");
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
	MarkovChain chain = new MarkovChain(options.tuples);
	options.seeds.map!tokens.each!(seed => chain.seed(seed));
	options.inputs.map!tokens.each!(input => chain.train(input));

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
			"help|h",   &help,
			"input|i",  &options._inputs,
			"length|l", &options._length,
			"output|o", &options._output,
			"seeds|s",  &options._seeds,
			"tuple|t",  &options._tuples
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
		stderr.writeln(e.msg);
	}
}
