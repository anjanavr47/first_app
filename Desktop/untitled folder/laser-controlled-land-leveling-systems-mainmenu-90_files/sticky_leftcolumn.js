// JQuery for Sticky Left COlumn

$(function(){
	
	function sticky_nav(left_nav){
			var win = $(window);
			var nav_top = left_nav.offset().top;
			
			function toggle_Sticky_nav(){
				if(win.scrollTop() > nav_top){
					left_nav.addClass('sticky')
				}else{
					left_nav.removeClass('sticky')
				}
				
			}
			win.scroll(function(){
				toggle_Sticky_nav();
			})
			
			toggle_Sticky_nav();
	}
	
	sticky_nav($('#leftcolumn'));
	
});