# polo - Markov Polo
For when you really need markov chains on your command line.

Polo now uses the [D markov library](https://www.github.com/Mihail-K/markov), and hence fits into a quarter of the lines of code, compared to what it was before.

## Why use it?
Ever been faced with the problem of having to write a needlessly long document, when all you have is your command line? 
Faced with a sudden need to write a resume, but all you have is a terminal? Got an English paper due tomorrow, but all you have ready is your shell?

As tempting as it might sound, writing 3000 words in nano or emacs is really not as fun as you think it might be, (take it from experience), but there is a better way! Just grab the plain texts for your source material (and some stuff from your own reading library, in our case, a collection of [FIMFiction clopfics](https://www.fimfiction.net/group/12/clopfics)) and fire away.

```bash
cat "lord of the rings fellowship.txt" "my clopfics.txt" | polo -l 3000 > assignment1.txt
```

And you're done! 3000 words in about as many milliseconds.

> Merry and Pippin she gave small silver belts, each with a clasp wrought like a golden flower.
> To Legolas she gave a breathy moan at the attention her plot had been receiving.

Voila! A+ material right there: Meaningful quotes of the relevant text plus that raunchy twist that English teachers crave. Not only have you produced a marvel that will take whomever happens to be grading it entirely by surprise, you have saved yourself hours of meaningless labour. It's just win-win.

### What about Philosophy papers?

Of course, these are always particularly nasty. As tedious as the thought of spending 9 hours writing 6500 words of comparison between a religious work and a fantasy work might seem, we can speed up this process to take less than a second.

All you really need for this one is a copy of the King James bible, the plain text of the Fellowship of the Ring, and your choice of Harry Potter fanficiton. In this instance, we're using whatever the first result in Google was.

```bash
cat "king james.txt" "lord of the rings fellowship.txt" "harry.txt" | polo -l 6500 > philo1.txt
```

And you're done! Again! All that's left to do is print the paper and give it a quick once over, go as to glimpse that which you have wrought.

> 14:2 Holy shit, pipe weed.

I think that's a perfect summary of everything that just went into that. You're ready to go.

## More than just text

Polo isn't just limited to writing your literary assignment for you, you know. It's got a vast number of applications in school, your workplace, and bunch of other things that I really can't name right now.

 - Resumes
 - Patient records
 - Wikipedia articles
 - Design documents
 - Detailed design documents
 - Documentation
 - Unit tests
 - Angular scopes
 - Rails asset pipelines
 - Code gen

And other things you'd rather not be doing yourself, and all of them from your command line.

## Building

Just clone the repo locally and build. Building polo is easy with dub, and without.

With DUB
```bash
dub build --build=release
```

Without DUB
```bash
dmd source/app.d -release -ofpolo && rm polo.o
```

Polo has no outside dependencies, and can now be copied to your desired location.

## License 

MIT
