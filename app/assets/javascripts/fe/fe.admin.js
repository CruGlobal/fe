// Prevent duplicate event handler bindings during Turbo navigation
window.feAdminEventHandlersBound = window.feAdminEventHandlersBound || false;

$(document).on('ready turbo:load', function () {
  // Prevent multiple bindings of the same handlers during Turbo navigation
  if (window.feAdminEventHandlersBound) {
    // Still need to run these on every page load
    setUpJsHelpers();
    setUpSortables();
    fixGridColumnWidths();
    return;
  }
  window.feAdminEventHandlersBound = true;

  setUpJsHelpers();
	$(document).on('ajaxStart', function() {
		$('#status').show();
	}).on('ajaxComplete', function() {
		$('#status').hide();
		setUpJsHelpers();
	});

  $(document).on('click', '.link-show-xml', function() {
    let div = $(this).closest('.choices_section')
    $('.xmlChoices', div).show();
    $('.link-show-csv', div).show();
    $('.link-show-xml', div).hide();
    $('.csvChoices', div).hide();
  });

  $(document).on('click', '.link-show-csv', function() {
    let div = $(this).closest('.choices_section')
    $('.csvChoices', div).show();
    $('.link-show-xml', div).show();
    $('.link-show-csv', div).hide();
    $('.xmlChoices', div).hide();
  });


	$(document).on('click', '.lbOn', function() {
		if ($('#dialog-help')[0] == null) {
			$('body').append('<div id="dialog-help" style="display:none" title="Help!"><p><span id="dialog-help-message"></span></p></div>');
		}
		$.get($(this).attr('href'), function(content) {
			$('#dialog-help-message').html(content);
			$('#dialog-help').dialog({
				modal: true,
				width: 500,
				buttons: {
					Close: function() {
						$(this).dialog('close');
					}
				}
			});
		});
		return false;
	});

	$(document).on('click', '.close_prop', function() {
  	$('#element_form_' + $(this).attr('data-dom_id')).hide();
	  $('#element_' + $(this).attr('data-dom_id')).show();
		return false;
	});

	$(document).on('click', 'input[name=future_affect][type=radio]', function() {
    if ($(this).val() == "yes") {
      $(".future_answer, .future_target, .future_page").show();
    } else if ($(this).val() == "no") {
      $(".future_answer, .future_target, .future_page").hide();
      $('#element_conditional_id').val('');
      $(".future_target input").removeAttr("checked");
      $("#element_conditional_type_").prop("checked", true);
    }
  });

  $(document).on('click', "input[name='element[conditional_type]'][type=radio]", function() {
    if ($(this).val() == "Fe::Page") {
      $(".future_page").show();
    } else if ($(this).val() == "Fe::Element") {
      $(".future_page").hide();
    }
  });

  // Run these on every page load
  setUpSortables();
  fixGridColumnWidths();
});
// used by form designer

let currentTab = 'pages_list';

window.switchTab = function switchTab(toTab) {
  if(currentTab != null) $('#tab-' + currentTab).removeClass('active');
  $('#tab-' + toTab).addClass('active');
  currentTab = toTab;
  if (toTab == 'pages_list') {
    setUpSortables();
  }
}

window.selectPage = function selectPage() {
  let el = $('#link-page-name');
  clearCurrentElement();
  el.addClass('active');
  switchTab('properties');

  if($('#page_label').length > 0) $('#page_label').focus();
}

window.selectElement = function selectElement(id) {
  let el = $(id);
  clearPageName();
  clearCurrentElement();
  el.addClass('active');
  // snapElementProperties(el);
  activeElement = id;
  switchTab('properties');

  // if( $('#element_label')) $('#element_label').focus();
}

window.clearCurrentElement = function clearCurrentElement() {
  if (activeElement != '' && $(activeElement)) {
    $(activeElement).removeClass('active');
  }
}

window.clearPageName = function clearPageName() {
  $('#link-page-name').removeClass('active');
}

window.snapElementProperties = function snapElementProperties(el) {
  let propsTop = Position.cumulativeOffset(el)[1] - 160;
  if (propsTop < 0) propsTop = 0;
  $('#panel-properties-element').css({'margin-top': propsTop});
}

window.addError = function addError(id) {
  $('#' + id).addClassName('fieldWithErrors');
}

// convert label to slug
window.updateSlug = function updateSlug(source, dest) {
  let label = $(source).val();
  let slug = $(dest).val();
  if( label == null || slug == null) return;  // oh oh

  label = label.strip();
  slug = slug.strip();

  if( label != '' && slug == '' ) {  // if slug is empty lets copy label to it
    slug = label.toLowerCase();
    slug = slug.replace(/[^a-z0-9]/, '_');   // only alpha-numeric
    slug = slug.replace(/_{2,}/, '_');       // compact double hyphens down to one
    slug = slug.replace(/_$/, '');           // remove trailing underscores
    slug = slug.replace(/^([0-9])/, '_$&')   // can't begin with a digit, so preprend an underscore
    if( slug.length > 36 ) slug = slug.slice(0, 36)  // max length

    $(dest).value = slug
    $(dest).focus();
  }
}
