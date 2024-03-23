# Register frame

## General information

This is a background application that, when activated ("Cntrl + ;"), displays a window with all system register information.

## Program start

We use the "DOS-box" emulator
In the command line, enter
```ASM
>>> frame_pr.asm
>>> tlink /t frame_pr.obj
>>> frame_pr.com <fr_len> <fr_high> <frame_colour> <frame_kind> <heading>:<text>.
```

## Example

Input:

![s](https://github.com/A-Elbereth-Gilthoniel/images/blob/main/press_frame_input.png)

Activation (Cntrl+;):

![sd](https://github.com/A-Elbereth-Gilthoniel/images/blob/main/press_frame_output.png)

