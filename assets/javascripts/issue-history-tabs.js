function add_new_tab(id, url, tab_header, tab_content) {
  var header_content = '<li>';
  header_content += '<a href="' + url + '?tab=' + id + '" id="tab-' + id + '" onclick="showTab(\'' + id + '\'); this.blur(); return false;" class="no_line in_link" data-remote="true"><span>' + tab_header + '</span></a>';
  header_content += '</li>';
  $('#history_tabs > .tabs > ul:first').append(header_content);

  $('#history_tabs').append('<div class="tab-content" id="tab-content-' + id + '" style="display:none">' + (tab_content || tab_content == '' ? tab_content : '<div class="preloader"></div>') + '</div>');

  if (!tab_content && tab_content != '') {
    var link = $('#tab-' + id);
    link.click(function(event) {
      if ($('#tab-content-' + id).attr('data-loaded')) {
        $(this).removeAttr('data-remote');
        return;
      }
      $('#tab-content-' + id).attr('data-loaded', 1);
    });
  }
}

$(document).ready(function () {
  var everythingLoaded = setInterval(function() {
    if (/loaded|complete|interactive/.test(document.readyState)) {
      clearInterval(everythingLoaded);
      $('.tabs-buttons').hide();
      $(window).off("resize", displayTabsButtons);
    }
  }, 100);

  var has_comments = false;
  var has_history = ($('.journal').length > 0);
  var has_timelog = ($('#issue_timelog').length > 0);
  var has_changesets = ($('#issue-changesets').length > 0);

  if (has_changesets) {
    has_comments = true;
    chaneset_el = $('#issue-changesets').clone();
    $('#issue-changesets').remove();
    chaneset_el.clone().appendTo('#tab-content-comments');
    chaneset_el.clone().appendTo('#tab-content-history');
    chaneset_el.remove();
  }

  $('.journal.has-notes, .journal.has-details, .journal:has(a[href*="/attachments/"])').each(function (index) {
    has_comments = true;
    var el = $(this).clone();
    if(!el.hasClass('has-system')){
      el.appendTo($('#tab-content-comments'));
    }
  });

  if (has_timelog) {
    $('#issue_timelog').appendTo('#tab-content-timelog');
  }
  else {
    $('#tab-timelog').remove();
  }

  if (has_history) {
    $('#history').appendTo('#tab-content-history');
  }
  else {
    $('#tab-history').remove();
  }

  if(has_comments && $('#tab-content-comments').children().length == 0) {
    has_comments = false 
  }

  if (!has_comments) {
    $('#tab-comments').remove();
    $('#tab-content-history').show();
  }

  if (!has_comments && !has_history && !has_timelog && !has_changesets){
    $('#history_tabs').remove();
  }
  else {
    $('#history_tabs').insertAfter('div.issue:first')
  }

  if ($('.tabs a.selected').length == 0) {
    $('.tabs a').first().addClass('selected');
  }

});