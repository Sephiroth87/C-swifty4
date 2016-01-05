C-swifty4
============================
**This project is a work in progress and is no way near complete!**

<p align="center">
	<img src="https://raw.githubusercontent.com/Sephiroth87/C-swifty4/master/Images/hello.png" alt="Hello world" />
</p>
<p align="center">
	<a href="https://gitter.im/Sephiroth87/C-swifty4?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge"><img src="https://badges.gitter.im/Join%20Chat.svg" alt="Join the chat at https://gitter.im/Sephiroth87/C-swifty4" /></a>
</p>

C-swifty4 is a cycle accurate Commodore 64 emulator for OS X, iOS and tvOS, written entirely in Swift.

This is a side project I started for a bunch of reasons, mostly because I was interested in building an emulator from scratch (and the C64 being my first computer I always wanted to take a deeper look on how it actually worked), and to learn some Swift along the way... This means that this project is not meant to be a “professional” emulator, it might not even be finished ever, but some people might find it interesting (and I needed some place to host my repo anyway).
Also, code structure, commenting and stuff is going to change a lot...

On a side note, unfortunately I ended up not using many of Swift’s unique features because they are kinda slow for the kind of performance needed for accurate emulation :(

FAQ
============================

#### How do I build it?

C-swifty4 requires Swift 2.0, so you’ll need to use Xcode 7 or higher to build it.
Works on OS X 10.10 and iOS8 mostly because it’s the only place I tested, so it might work with older versions...

You’ll need to provide your own C64 ROM dumps to make it work, so replace the files in the `ROM` folder with the appropriate ones (kernal and basic need to be 8192 bytes, chargen is 4096, 1541 is 16384).

Also, the iOS version will look for program files in the `Programs` folder, so put them there before building.

Then just open the project file, build and run.

#### What works

* BASIC (unless some instructions I haven’t tested need the missing opcodes)
* Video (all video modes, some sprites functionalities)
* Keyboard (not all keys)
* Joystick 2
* Loading files (Supported *.prg files will be dumped in memory directly atm, so you’ll just need to type `RUN` to start them, *.txt files will be typed in as text)
* Standard .d64 disk files

#### What doesn’t work

* Sound
* Joystick 1
* Timers
* VIC interrupts
* Loading tapes/disks
* Playing games probably
* Some opcodes
* FPS limiting (runs as fast as it can right now)
* A lot of things basically...

#### Lorenz Test Suite compatibility

Passing 122/275 tests

License
-----------------------------
Copyright (c) 2014. [Fabio Ritrovato](https://twitter.com/Sephiroth87)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
