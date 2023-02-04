# gcodeToThumbnail
A command line tool to give PrusaSlicer GCode files icons in macOS Finder.

I got tired of my gcode files looking like 

![](images/before.png) when they could look like this: ![](images/sample.png)

To Install:

* install the compiled `gcodeToThumbnail` in `/usr/local/bin/` If you don't want to compile it yourself, grab the compiled code from [Releases](https://github.com/DavidPhillipOster/gcodeToThumbnail/releases/tag/1.0)
* In Prusa Slicer, in Printer Settings, set the thumbnail size to 128x128:

   ![](images/128x128.png)

This will cause PrusaSlicer to append a base64-encoded 128x128 .png image of the gcode to near the end of the gcode file.

`gcodeToThumbnail` takes .gcode files as arguments on the command line, opens them read-only, reads the .png out of them, and tells Finder to add
the image as the file's icon.

PrusaSlicer is supposed to run  automatically for you if you tell it to in Print Settings:
  ![](images/printSettings.png) 

but that doesn't work for me.

I have to run `gcodeToThumbnail` from the command line, passing the .gcode file (You can drag from Finder to Terminal and it will fill in the absolute path for you.) 

But when I do, it works, so now my .gcode files have decent icons in Finder.

## License

Apache 2 [License](LICENSE)


