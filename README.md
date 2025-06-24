## Learn OpenGL

This is my go at implementing all (or at least, most) of the lessons and exercises in the
famous [Learn OpenGL site](https://learnopengl.com).

All of the main lessons are complete, including the additional exercises, although not all of the guest articles.
I've also taken the liberty of adding a few exercises Programming
[Computer Graphics Programming in OpenGL](https://www.packtpub.com/en-us/product/computer-graphics-programming-in-opengl-with-c-edition-3-9781836641186).

Unlike the original, I wrote the application code in [Odin](https://odin-lang.org/), rather than C++.
This is mostly due to preference, but also because Odin has a lot of convenient features that make it handy for writing
graphics applications.

Also unlike the original, rather than creating individual applications for each exercise, I've created a single
application that can run each exercise.

### Build from source

In order to build the application from source, you'll need to have the
[Odin compiler](https://odin-lang.org/docs/install/) installed.

From the root folder of the project, simply run `odin run src -o:speed` to build and run the application.

You can build without running using the command `odin build src -o:speed -out:<whatever name you want>`.
This will produce an executable relative to your current directory.
Bear in mind that the executable needs to be run from the root directory, as it reads resource files relative
to the current working directory.

### Legal Stuff

[Learn OpenGL](https://learnopengl.com/About) and the code samples are under the terms of the CC BY-NC 4.0 license,
and the author - Joey de Vries - specifically asks that his full name be provided.
I didn't directly copy the code (I wrote most of it in another language, after all), but I figure it's good form
to list the license here anyways.

The media content, including the textures and models, are provided by Learn OpenGL under the CC BY 4.0 license.

The Crimson Text font is provided under the SIL Open Font License, Version 1.1.

The Odin programming language and its compiler are provided under the BSD-3-Clause license.

Otherwise, all of the code is written by me, and is not licensed. No copying. Do your own homework.
