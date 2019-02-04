# counts items to highlight so we can choose the best hint set

BEGIN {
    n_matches = 0;

    highlight_patterns = ENVIRON["PICKER_PATTERNS"]
    blacklist = "(^\x1b\\[[0-9]{1,5}m|^|[[:space:]])"ENVIRON["PICKER_BLACKLIST_PATTERNS"]"$"
}

{
    line = $0;
    while (match(line, highlight_patterns)) {
        post_match = substr(line, RSTART + RLENGTH);
        line_match = substr(line, RSTART, RLENGTH);

        if (line_match !~ blacklist) {
                hint = hint_by_match[line_match]
                if (!hint) {
                    hint_by_match[line_match] = n_matches++
                }
        }
        line = post_match;
    }
}

END {
    print n_matches
}
