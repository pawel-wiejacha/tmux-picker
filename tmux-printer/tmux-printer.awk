#!/usr/bin/env gawk

function tput_color(statement)
{
  if (!match(statement, "(bg|fg)=(.*)", color_groups))
    return statement

  layer=color_groups[1]
  color=color_groups[2]

  if (layer == "bg") {
    applied_styles[current_bg] = "0"
    current_bg=statement
    applied_styles[current_bg] = "1"
    capname="setab"
  } else {
    applied_styles[current_fg] = "0"
    current_fg=statement
    applied_styles[current_fg] = "1"
    capname="setaf"
  }

  if (match(color, "colou?r([0-9]+)", color_code_groups)) {
    params = color_code_groups[1]
  }

  if (color == "black")
    params="0"
  if (color == "red")
    params="1"
  if (color == "green")
    params="2"
  if (color == "yellow")
    params="3"
  if (color == "blue")
    params="4"
  if (color == "magenta")
    params="5"
  if (color == "cyan")
    params="6"
  if (color == "white")
    params="7"
  if (color == "default") {
    if (layer == "bg")
      applied_styles[current_bg] = "0"
    else
      applied_styles[current_fg] = "0"

    return reset_to_applied_styles()
  }

  return "$(tput " capname " " params ")"
}

function reset_to_applied_styles() {
  style_output = "$(tput sgr0)"

  for (applied_style in applied_styles) {
    if (applied_styles[applied_style] == "1") {
      style_output = style_output tput(applied_style)
    }
  }

  return style_output
}

function unset_applied_styles() {
  for (applied_style in applied_styles) {
    if (applied_styles[applied_style] == "1") {
      applied_styles[applied_style] = "0"
    }
  }

  return "$(tput sgr0)"
}

function tput_style(statement) {
  match(statement, /(no)?(.*)/, style_groups)

  disable_style = style_groups[1] == "no"
  style_to_apply = style_groups[2]
  style_output = ""

  if (statement == "none") {
    return unset_applied_styles()
  }

  if (disable_style) {
    applied_styles[style_to_apply]="0"
    style_to_apply = ""
    style_output = reset_to_applied_styles()
  } else {
    applied_styles[style_to_apply] = "1"
  }

  if (style_to_apply == "bright")
    style_output = "$(tput bold)"
  if (style_to_apply == "bold")
    style_output = "$(tput bold)"
  if (style_to_apply == "dim")
    style_output = "$(tput dim)"
  if (style_to_apply == "underscore")
    style_output = "$(tput smul)"
  if (style_to_apply == "reverse")
    style_output = "$(tput rev)"
  if (style_to_apply == "italics")
    style_output = "$(tput sitm)"

  return style_output
}

function tput(statement)
{
  if (statement ~ /^(bg|fg)=/)
    return tput_color(statement)
  else
    return tput_style(statement)
}

BEGIN {
  PATTERN_FORMAT="#\\[([^\\]]*)\\]"
}

{
  input = $0
  output = ""

  pos = 1
  prev_pos = pos

  while (match(input, PATTERN_FORMAT, input_groups)) {
    prev_pos = pos
    pos += (RSTART + RLENGTH - 1)
    rstart = RSTART

    styles_raw = input_groups[1]
    split(styles_raw, styles, ",")

    for (i in styles) {
      output_styles = output_styles tput(styles[i])
    }

    from = prev_pos
    to = rstart - 1

    output = output substr($0, from, to) output_styles
    input = substr($0, pos)
  }

  output = output substr($0, pos) "$(tput sgr0)"
}

END {
  print output
}
