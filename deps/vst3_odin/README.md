This software is untested and pre-alpha, PRs welcome!

# vst3_odin

Pure odin port of the VST3 API 

In a similar vein to [vst3-sys](https://github.com/RustAudio/vst3-sys.git) for Rust: we do not distribute the SDK nor try and wrap it in abstractions, just port compatible
bindings to the COM API. The full SDK can be found at sdk.steinberg.net or cloned from github [here](https://github.com/steinbergmedia/vst3sdk). 

## Usage

Copy the vst3 folder into your project and start coding!

## Examples

![Screenshot of tone_generator](https://gitlab.com/pan_fx/vst3_odin/-/raw/master/media/tone_generator_active.png?inline=false "Active")

The examples currently only build for Linux. `tone_generator` requires X11 and glx.

Before building the examples make sure you audit `build.sh` as it modifies your home directory.

You can build the examples using:

```
cd /path/to/vst3_odin
chmod u+x build.sh
./build.sh
```

The two current examples are `gain_no_gui` and `tone_generator` which can be un/commented out for speed. 

## Road Map

- [x] Linux Support 
- [x] No GUI example
- [x] OpenGL context creation in parented X11 window
- [ ] Windows Support - This should be as simple as porting the gl context creation and checking COM works.
- [ ] Direct3D Example - Once we have windows support, an example using Direct3D would be nice. 
- [ ] Mac OS Support - This should be as simple as porting the gl context creation and checking COM works. Mac OS is a bit weird with bundles too, maybe something to watch out for?
- [ ] Metal Example - Once we have windows support, an example using Metal would be nice. 

## Completeness and Contributions

If you see anything on the road map you feel you would like to implement, feel free to send me a message or make a PR.

## Credits 

* [CPLUG](https://github.com/Tremus/CPLUG.git) the examples would have been impossible without Tremus' invaluable work on creating C plug-in wrappers. Thank you very much for your
work and keeping things in the public domain.
* [REAPER](https://www.reaper.fm/) is good for 'real-world' plugin testing.
* The [JUCE](https://github.com/juce-framework/JUCE.git) framework's AudioPluginHost is incredibly useful for debugging. 
* [rigtorp/SPSCQueue](https://github.com/rigtorp/SPSCQueue.git) The SPSC Queue in the examples is a derivative work of this queue implementation.

VST is a trademark held by Steinberg Media Technologies, GMBH.  

## License
`vst3_odin` is licensed under the terms of the GNU GPLv3 license. This port is a derivative work of the original SDK, and while we do not redistribute any of the original source code, it was not made in isolation. 
