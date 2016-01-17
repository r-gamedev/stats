var tooltipFunction = function () {
  var s = '<b>' + this.x + '</b>';
  var sortedPoints = this.points.sort(function(a, b){
    return ((a.y > b.y) ? -1 : ((a.y < b.y) ? 1 : 0));
  });

  $.each(sortedPoints, function () {
    s += '<br/><span style="color:'+ this.series.color +'">\u25CF</span> ' + this.series.name + ': ' +
    this.y;
  });

  return s;
}

function chartfix() {
  try {
    $($("[id^=chart]").first()).highcharts()
  } catch (err) {
    console.log("failed to update highcharts")
    setTimeout(chartfix, 500);
    return;
  }

  $("[id^=chart]").each(function (e) {
    try {
      $(this).highcharts().options.tooltip.formatter = tooltipFunction;
    } catch (err) {
      debugger;
      console.log("failed to update highcharts")
      return;
    }
  })
  console.log("chartfix.js: Highcharts updated.");
}

$().ready(function() {
  chartfix();
})
// $("#chart-3").highcharts().series[0].update(