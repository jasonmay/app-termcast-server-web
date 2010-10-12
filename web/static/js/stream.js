var INTERVAL_ID;
var COLS = 80;
var ROWS = 24;

// two different locks: client side and server side.
//
// First level lock: If we're downloading the ajax response,
// prevent beginning a download from a succeeding timer process.
//
// Second level lock: When processing the terminal screen, don't
// let any other webserver processes begin. Without this, the
// terminal frames will not cache properly.

var downloading;
var pos_elems = [];

$(function() {
    tc = $('#container');

    for (var row = 0; row < ROWS; ++row) {
        for (var col = 0; col < COLS; ++col) {
            var span = '<span id="pos-' + row + '-' + col + '">&nbsp;</span>';
            $('#container').append(span);
        }
        tc.append('<span></span><br />');
    }

});

function termcast_cb(data) {
    downloading = 1;
    if (typeof(data) === 'object') {
        var tc = $('#container');

        for (var obj in data) {
            if (obj.fresh) {
                for (var row = 0; row < ROWS; ++row) {
                    for (var col = 0; col < COLS; ++col) {
                        var selector = '#pos-' + row + '-' + col;
                        var content = obj.fresh[row][col].v;
                        if (content == ' ') {
                            $(selector)
                                .text('.')
                                .css({color: 'black'});
                        }
                        else {
                            $(selector)
                                .text(content)
                                .css({color: 'white'});
                        }
                    }
                }
            }
            else if (obj.diff) {
                for (var change in obj.diff) {
                    var row  = change[0],
                        col  = change[1],
                        diff = change[2];

                    if (diff) {
                        var selector = '#pos-' + row + '-' + col;

                        if (diff['v']) {
                            $(selector)
                                .text(content)
                                .css({color: 'white'});
                        }
                    }
                }
            }
        }
    }
    else {
        clearInterval(INTERVAL_ID);
        console.log('got recv, but invalid data');
        window.location = '/';
    }
    downloading = 0;
}

function update_termcast(res_type, stream_id, client_id) {
    if (downloading) { console.log('still downloading'); return; }
    downloading = 1;
    var url = '/socket/' + stream_id + '/' + res_type + '?client_id=' + client_id;
    console.log('send');
    $.get(url, termcast_cb);
}

function start_stream(stream_id, client_id) {
    update_termcast('fresh', stream_id, client_id);
    INTERVAL_ID = setInterval(
        "update_termcast('diff', '" + stream_id + "', '" + client_id + "')",
        300
    );
}
