var Notify = {

    notice: function(msg) {
        $('.notice-message').html(msg);
        $('.notice').show();
    },
    clear_notice: function() {
        $('.notice').hide();
        $('.notice-message').html('');
    }
};


var RPXUtil = {
    unmap: function(open_id) {

        $.get(RPXUtil.unmap_url,
                { 'open_id': open_id },
                function(data) {
            Notify.clear_notice();
            Notify.notice(data);
        });
    }
};


