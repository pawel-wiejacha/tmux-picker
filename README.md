# tmux-picker

tmux-picker: Selecting and copy-pasting in terminal using Vimium-like hint mode for tmux.

This is a slimmed-down, improved and extended fork of [tmux-fingers](https://github.com/Morantron/tmux-fingers). Check [Acknowledgements](#acknowledgements) for comparison.

# Usage

Press ( <kbd>Meta</kbd> + <kbd>F</kbd> ) to enter **[picker]** hint mode, in which relevant stuff (e.g. file paths, git SHAs) in the current
pane will be highlighted along with letter hints. By pressing those letters, the highlighted match will be copied to the system clipboard.

By default, following items are highlighted:

* File paths (that contain `/`)
* git SHAs
* numbers (4+ digits)
* hex numbers
* IP addresses
* UUIDs

You can press:

* <kbd>SPACE</kbd> to highlight additional items (everything that might be a file path, if it's longer than 4 characters).
* <kbd>ESC</kbd> to exit **[picker]** hint mode

# Installation

* Clone the repo: `git clone https://github.com/pawel-wiejacha/tmux-picker ~/.tmux/tmux-picker`
* Add `run-shell ~/.tmux/tmux-picker/tmux-picker.tmux` to your `~/.tmux.conf`
* Reload tmux config by running: `tmux source-file ~/.tmux.conf`

# Configuration

- Edit `~/.tmux/tmux-picker/tmux-picker.tmux`, where you can change:
    - `PICKER_KEY` (default <kbd>Meta</kbd> + <kbd>F</kbd>, without the prefix)
    - `PATTERNS_LIST1` - regex patterns highlighted after pressing `PICKER_KEY`
    - `PATTERNS_LIST2` - regex patterns highlighted after pressing <kbd>SPACE</kbd> in hint mode 
    - `BLACKLIST` - regex pattern describing items that will not be highlighted
    - `PICKER_COPY_COMMAND` - command to execute on highlighted item
        - default is: `xclip -f -in -sel primary | xclip -in -sel clipboard`, which copies item to clipboard
    - `PICKER_COPY_COMMAND_UPPERCASE` - command to execute on highlighted item, when hint was typed using uppercase letters
        - default is `bash -c 'arg=\$(cat -); tmux split-window -h -c \"#{pane_current_path}\" vim \"\$arg\"'`, which executes `vim` in a sidebar
    - `PICKER_HINT_FORMAT` - describes hint color/style.
        - Default is `#[fg=color0,bg=color202,dim,bold]%s`, but you can change it to `bg=yellow` or something if your terminal does not support 256 colors
    - `PICKER_HIGHLIGHT_FORMAT` - describes highlighted item color/style

# Requirements

* tmux 2.2+
* bash 4+
* gawk 4.1+ (which was released in 2013)

# Acknowledgements

It started as a fork of [tmux-fingers](https://github.com/Morantron/tmux-fingers). I would like to thank to [Morantron](https://github.com/Morantron) (the tmux-fingers author) for a really good piece of code!

My main problem with tmux-fingers was that it did not support terminal colors (it strips them down). I have fancy powerline prompt, colored `ls`, zsh syntax highlighting, colored git output, etc. So after entering tmux-fingers hint mode it was like *'WTF? Where are all my colors? Where am I? Where's the item I want to highlight??!'*. I could enable capturing escape sequences for colors in `tmux capture-pane`, but it would break tmux-fingers pattern matching. 

My other problem with tmux-fingers was that it was sluggish. So I started adding color support to `tmux-fingers` and improving its performance. I had to simplify things to make it reliable. I completely rewrote awk part, added Huffman Coding, added second hint mode. I therefore decided to fork and rename project instead of submitting pull requests that turn things upside down.

## Comparison

Comparing to tmux-fingers, tmux-picker:

- **supports terminal colors** (does not strip color escape codes)
- uses Huffman Coding to generate hints (**shorter hints**, less typing)
    - and supports unlimited number of hints
- is **noticeably faster** 
    - and does not have redraw glitches
- has **better patterns** and **two modes** (with different pattern sets)
    - and blacklist pattern
- is self-contained, smaller and easier to hack

Like tmux-fingers, tmux-picker still supports: 

- hints in copy-mode
- split windows/multiple panes
- zoomed panes
- two different commands
- configurable hint/highlight styles
- configurable patterns

# How it works?

The basic idea is:

- create auxiliary pane with the same width and height as the current pane
- `tmux capture-pane -t $current_pane | gawk -f find-and-highlight-patterns.awk` to auxiliary pane
- swap panes (the easiest way not to break things like copy-mode) 
- read typed keys and execute user command on selected item

# License

[MIT](https://github.com/pawel-wiejacha/tmux-picker/blob/master/LICENSE)
