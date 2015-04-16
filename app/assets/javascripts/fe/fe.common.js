function setUpSortables() {
	$('[data-sortable]').sortable({axis:'y', 
                                  items: '> li.sortable',
																  dropOnEmpty:false, 
																  update: function(event, ui) {
																		sortable = this;
																		$.ajax({data:$(this).sortable('serialize',{key:sortable.id + '[]'}),
																						complete: function(request) {$(sortable).effect('highlight')}, 
																						success:function(request){$('#errors').html(request)}, 
																						type:'POST', 
																						url: $(sortable).attr('data-sortable-url')
																					 })
																		},
                                  stop: function(event, ui) {
                                    before_dropper = $('li.before-container[data-element_id="'+ui.item.data('element_id'));
                                    if (before_dropper.length > 0) {
                                      before_dropper.detach();
                                      before_dropper.insertBefore(ui.item);
                                    }
                                    after_dropper = $('li.after-container[data-element_id="'+ui.item.data('element_id'));
                                    if (after_dropper.length > 0) {
                                      after_dropper.detach();
                                      after_dropper.insertAfter(ui.item);
                                    }
                                  }
	});
	$('[data-sortable][data-sortable-handle]').each(function() {
		handle = $(this).attr('data-sortable-handle');
		$(this).sortable("option", "handle", handle);
	});
	
	$('.droppable').droppable({
		activeClass: 'droppable-active',
    hoverClass: 'droppable-hover',
		drop: function( event, ui ) {
			$.post($(this).attr('data-url'), {draggable_element: ui.draggable.attr('id')}, function() {}, 'script')
		},
    activate: function( event, ui ) {
      $draggable = ui.draggable;
      $container = $draggable.parents("li.element.container")
      if ($container.length == 1) {
        $container.parent().find('li.around-container[data-element_id="'+$container.data('element_id')+'"]').addClass('droppable-active')
      } else {
        $('li.around-container').removeClass('droppable-active');
      }
    },
    deactivate: function( event, ui ) {
      $draggable = ui.draggable;
      $container = $draggable.parents("li.element.container")
      if ($container.length == 1) {
        $container.parent().find('li.around-container[data-element_id="'+$container.data('element_id')+'"]').removeClass('droppable-active')
      } else {
        $('li.around-container').removeClass('droppable-active');
      }
    }
	});
}

function setUpCalendars() {
	now = new Date();
	year = now.getFullYear() + 10;
	$('[data-calendar]').datepicker({changeYear:true,
																	 yearRange: '1950:' + year})
}

function setUpJsHelpers() {
		// ==================
		// Sortable
		setUpSortables();
		// ==================
		
		// ==================
		// Calendar
		setUpCalendars();
  	// ==================
		$(".tip[title], a[title]").tooltip()
}

function fixGridColumnWidths() {
	$("table.grid").each(function(i, grid) {
		num_columns = $(grid).find("th").length;
		if (num_columns > 0) {
			width = (100 / num_columns) + "%";
			$(grid).find("> tbody > tr > th").css("width", width);
			$(grid).find("> tbody > tr > td").css("width", width);
		}
	});
};
