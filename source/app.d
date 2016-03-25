
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
    string _mode = "generate";
    string _format = "bin";

    string _dictionary;
    string[] _inputs;
    string _output;

    size_t _length;
    size_t[] _tuples;

    string[] _seeds;
    string _filter;

    @property
    File dictionary()
    {
        return File(_dictionary, "rb");
    }

    @property
    string format()
    {
        switch(_format.toLower)
        {
            case "bin":
            case "json":
                return _format.toLower;
            case "b":
            case "binary":
                return "bin";
            case "j":
                return "json";
            default:
                stderr.writeln("Unsupported format: ", _format);
                stderr.writeln("  Defaulting to binary.");
                return _format = "bin";
        }
    }

    @property
    string mode()
    {
        switch(_mode.toLower)
        {
            case "train":
            case "generate":
                return _mode.toLower;
            case "t":
                return "train";
            case "g":
                return "generate";
            default:
                stderr.writeln("Unsupported format: ", _mode);
                stderr.writeln("  Defaulting to generate.");
                return _mode = "generate";
        }
    }

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
        File output = _output.length ? File(_output, "w") : stdout;

        return output;
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
    scope(exit) file.close;

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

void showHelp()
{
    writeln("Usage: polo [-dFfhilmost] -- ");
    writeln;
    writeln("Option   Long Option              Meaning");
    writeln(" -d       --dictionary=<file>      Sets the input dictionary file");
    writeln(" -F       --format=<bin|json>      Specifies the dictionary format");
    writeln("                                   (default: bin)");
    writeln(" -f       --filter=<pattern>       Regex filter applied to tokens");
    writeln(" -h       --help                   Show this message");
    writeln(" -i       --input=<file>           Adds an input file");
    writeln(" -l       --length=<#words>        Sets the output length in words");
    writeln(" -m       --mode=<train|generate>  Sets the operating mode");
    writeln("                                   (default: generate)");
    writeln(" -o       --output=<file>          Sets the output file");
    writeln(" -s       --seed=<text>            Adds a seed text");
    writeln(" -t       --tuple=<#size>          Adds a markov state tuple");
    writeln;
}

MarkovChain!string decodeChain(Options *options)
{
    File dictionary = options.dictionary;
    scope(exit) dictionary.close;

    if(options.format == "bin")
    {
        return decodeBinary!string(dictionary);
    }
    else
    {
        return decodeJSON!string(dictionary);
    }
}

void encodeChain(MarkovChain!string *chain, Options *options)
{
    File output = options.output;

    if(options.format == "bin")
    {
        encodeBinary(*chain, output);
    }
    else
    {
        encodeJSON(*chain, output);
    }
}

MarkovChain!string createChain(Options *options)
{
    if(options._dictionary.length)
    {
        return decodeChain(options);
    }
    else
    {
        return MarkovChain!string(options.tuples);
    }
}

void seed(MarkovChain!string *chain, Options *options)
{
    options.seeds.map!(s => s.tokens(options.filter)).each!(seed => chain.seed(seed));
}

void train(MarkovChain!string *chain, Options *options)
{
    options.inputs.map!(s => s.tokens(options.filter)).each!(input => chain.train(input));
}

void generate(MarkovChain!string *chain, Options *options)
{
    File output = options.output;
    scope(exit) output.close;

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

void polo(Options *options)
{
    MarkovChain!string chain = options.createChain;

    if(options.mode == "generate")
    {
        if(options._dictionary.length == 0)
        {
            train(&chain, options);
        }

        seed(&chain, options);
        generate(&chain, options);
    }
    else if(options.mode == "train")
    {
        train(&chain, options);
        encodeChain(&chain, options);
    }
    else
    {
        assert(0);
    }
}

void main(string[] args)
{
    try
    {
        bool help;
        Options options;

        args.getopt(
            config.bundling,
            "dictionary|d", &options._dictionary,
            "format|F",     &options._format,
            "help|h",       &help,
            "filter|f",     &options._filter,
            "input|i",      &options._inputs,
            "length|l",     &options._length,
            "mode|m",       &options._mode,
            "output|o",     &options._output,
            "seeds|s",      &options._seeds,
            "tuple|t",      &options._tuples
        );

        if(help)
        {
            showHelp;
        }
        else
        {
            polo(&options);
        }
    }
    catch(Exception e)
    {
        stderr.write("Error: ");
        stderr.writeln(e.msg);
    }
}
