var INTERVAL_ID;

var DEBUG = 0;

var pos_elems = [];

function create_cell(tc, row, col) {
    var span = '<span';

    span += ' id="pos-' + row + '-' + col + '"';
    span += ' title="(' + row + ', ' + col + ')"';

    span += '>&nbsp;</span>';
    tc.append(span);
}

function create_origin(tc) {
    tc.append('<span class="legend">&nbsp;</span>');
}

function create_x_axis_node(tc, col) {
    var extra = '';

    if (col % 10 == 0) {
        extra = 'style="color: red"';
    }

    var val = col % 10;

    if (val == 0) {
        val = col / 10;
    }

    tc.append(
        '<span class="legend" title="' + col + '" ' + extra + '>'
        + val
        + '</span>'
    );
}

function create_y_axis_node(tc, row) {
    tc.append(
        '<span class="legend" title="' + row + '">'
        + (row % 10)
        + '</span>'
    );
}

function add_newline(tc) {
    tc.append('<br />');
}

function update_cell_value(cell, diff) {
    if (diff['v']) {
        var content = diff['v'];
        if (content == ' ') {
            content = '&nbsp;';
            diff['bo'] = 0;
        }
        cell.html(content);
    }
}

function canonicalize_data(diff) {
    var newdiff = diff;

    if (newdiff.bo === '0') { newdiff.bo = 0; }

    return newdiff;
}

var color_map = [
    '#000000', '#ca311c', '#60bc33', '#bebc3a',
    '#1432c8', '#c150be', '#61bdbe', '#c7c7c7',
];

var bold_color_map = [
    '#686868', '#df6f6b', '#70f467', '#fef966',
    '#6d75ea', '#ed73fc', '#73fafd', '#ffffff'
];

function color_cell(cell, diff) {

    var color;

    if (diff['bo']) {
        color = bold_color_map[diff['fg']];
    }
    else {
        color = color_map[diff['fg']];
    }

    bg_color = color_map[diff['bg']];

    cell.css({
        color: color,
        'background-color': bg_color
    });
}

function clear_cells(cols, lines) {
    for (line = 0; line < lines; line++) {
        for (col = 0; col < cols; col++) {
            var cell = _selector(line, col);
            $(cell).html('');
            $(cell).css({'background-color': 'black'});
        }
    }
}

function _selector(row, col) {
    return '#pos-' + row + '-' + col;
}

function write_cells(cols, lines) {
    tc = $('#container');

    if (DEBUG) {
        create_origin(tc);
    }

    if (DEBUG) {
        for (var col = 0; col < cols; ++col) { // top
            create_x_axis_node(tc, col);
        }
        add_newline(tc);
    }

    for (var row = 0; row < lines; ++row) {

        if (DEBUG) {
            create_y_axis_node(tc, row);
        }

        for (var col = 0; col < cols; ++col) {
            create_cell(tc, row, col);
        }
        add_newline(tc);
    }

}

function termcast_cb(data, cols, lines) {
    if (typeof(data) === 'object') {
        var tc = $('#container');

        for (j = 0; j < data.length; j++) {
            var change = data[j];
            var row  = change[0],
                col  = change[1],
                diff = canonicalize_data(change[2]);

            if (diff) {

                var cell = $( _selector(row, col) );

                if (diff['clear'])
                    clear_cells(cols, lines);

                if (diff['v'])
                    update_cell_value(cell, diff);

                if (diff['fg'] || diff['bg'])
                    color_cell(cell, diff);

            }
        }
    }
}

var cell_height = 16;
var spacing     = 1.35;
function set_font(context) {
    context.font = Math.floor(cell_height / spacing) + "pt Monaco,'Bitstream Vera Sans Mono',monospace";
    context.textBaseline = 'top';
}

function set_screen_value(screen, col, line, key, value) {
    if (!col) col = '0'; if (!line) line = '0';

    if (typeof(screen)            === 'undefined') screen            = {};
    if (typeof(screen[line])       === 'undefined') { screen[line]       = {}; }
    if (typeof(screen[line][col]) === 'undefined') screen[line][col] = {};

    screen[line][col][key] = value;
}

function get_screen_value(screen, col, line, key) {
    if (typeof(screen)            === 'undefined') return undefined;
    if (typeof(screen[line])       === 'undefined') return undefined;
    if (typeof(screen[line][col]) === 'undefined') return undefined;

    return screen[line][col][key];
}

function init_canvas(canvas, cols, lines) {
    var context = canvas.getContext('2d');

    // get the width of the letter M in our font
    set_font(context);
    var cell_width = context.measureText('M').width;
    canvas.width  = Math.floor(cell_width * cols);
    canvas.height = Math.floor(cell_height * lines * spacing);

    var border_width = 10;
    $('#caption').width(canvas.width + border_width * 2);
    // ugh, have to set the font again after adjusting the canvas geometry
    set_font(context);
}

function update_canvas(data, context, screen, cols, lines) {
    if (typeof(data) === 'object') {
        for (j = 0; j < data.length; j++) {
            var change = data[j];
            var line  = change[0],
                col  = change[1],
                diff = canonicalize_data(change[2]);

            if (diff) {
                context.fillStyle = bold_color_map[0];
                c_update_cell_value(col, line, context, diff, screen);

                if (diff['clear']) {
                    // hack to clear canvas
                    context.canvas.width = context.canvas.width;
                    set_font(context);
                }
            }
        }
    }
}

function preserve_or_assign(key, col, line, diff, screen) {
    if (typeof(diff[key]) === 'undefined') {
        if (get_screen_value(screen, col, line, key)) {
            diff[key] = get_screen_value(screen, col, line, key);
        }
    }
    else {
        set_screen_value(screen, col, line, key, diff[key]);
    }
}

function c_update_cell_value(col, line, context, diff, screen) {

    var cell_width = context.measureText('M').width;

    var mod_height = Math.floor(cell_height * spacing);

    // FIXME track previous bg so we aren't clobbering!!
    context.fillStyle = '#000';
    context.fillRect(
        col * cell_width,
        line * mod_height,
        cell_width, mod_height
    );

    c_update_cell_bg(col, line, context, diff, screen);

    context.fillStyle = color_map[7];
    c_update_cell_fg(col, line, context, diff, screen);

    preserve_or_assign('v', col, line, diff, screen);

    context.fillText(diff['v'], col * cell_width, line * mod_height);
}

function c_update_cell_bg(col, line, context, diff, screen) {
    return; // let's not use bg for now
    if (typeof(diff['bg']) === undefined) { return; }
    var bg_color   = color_map[diff['bg']];
    var cell_width = context.measureText('M').width;

    var mod_height = Math.floor(cell_height * spacing);

    context.fillStyle = bg_color;
    context.fillRect(
        col * cell_width,
        line * mod_height,
        cell_width, mod_height
    );
}

function c_update_cell_fg(col, line, context, diff, screen) {
    //return; // XXX
    var color;

    var map;

    preserve_or_assign('bo', col, line, diff, screen);

    if (diff.bo) {
        map = bold_color_map;
    }
    else {
        map = color_map;
    }

    if (typeof(diff.fg) === 'undefined') {
        fg = get_screen_value(screen, col, line, 'fg');
        if (typeof(fg) === 'undefined') {
            color = map[7];
        }
        else {
            color = map[fg];
        }
    }
    else {
        set_screen_value(screen, col, line, 'fg', diff.fg);
        set_screen_value(screen, col, line, 'bo', diff.bo);
        color = map[diff.fg];
    }


    context.fillStyle = color;
}
