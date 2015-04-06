/*
function hideDebtParagraphs() {
  $('.debt_lvl1, .debt_lvl2, .debt_lvl3').hide();
}

console.log('setting up document fePageLoad listener in pure js here ');
$(document).on("fePageLoad", function() {
  console.log('in fePageLoad pure js handler');
  hideDebtParagraphs();
  $('#total_28_2').on('totalChanged', function() {
    totalDebt = Number($('#total_28_2').val());
    hideDebtParagraphs();
    if (totalDebt < 100) {
      $('.debt_lvl1').show();
    } else if (totalDebt < 1000) {
      $('.debt_lvl2').show()
    } else {
      $('.debt_lvl3').show()
    }
  })
});
*/

console.log('setting up document fePageLoad listener in pure js here ');
$(document).on("fePageLoad", function() {
  console.log('in fePageLoad pure js handler');
});
