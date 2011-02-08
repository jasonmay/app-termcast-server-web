var INTERVAL_ID;
var COLS = 80;
var ROWS = 24;

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
        //console.log(diff['v']);
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

function _selector(row, col) {
    return '#pos-' + row + '-' + col;
}

$(function() {
    tc = $('#container');

    if (DEBUG) {
        create_origin(tc);
    }

    if (DEBUG) {
        for (var col = 0; col < COLS; ++col) { // top
            create_x_axis_node(tc, col);
        }
        add_newline(tc);
    }

    for (var row = 0; row < ROWS; ++row) {

        if (DEBUG) {
            create_y_axis_node(tc, row);
        }

        for (var col = 0; col < COLS; ++col) {
            create_cell(tc, row, col);
        }
        add_newline(tc);
    }

});

function termcast_cb(data) {
    console.log(data);
    if (typeof(data) === 'object') {
        var tc = $('#container');

        for (j = 0; j < data.length; j++) {
            var change = data[j];
            var row  = change[0],
                col  = change[1],
                diff = canonicalize_data(change[2]);

            if (diff) {

                var cell = $( _selector(row, col) );

                update_cell_value(cell, diff);
                color_cell(cell, diff);
            }
        }
    }
}

