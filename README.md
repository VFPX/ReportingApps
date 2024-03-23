# Reporting Apps
The default implementation of Visual FoxPro 9's Report Applications. Including the report output engine, the preview container, and the default Report Builder application, complete with a framework of Report Designer event handlers.

Includes the full source code for the following applications:

* ReportBuilder.APP

* ReportOutput.APP

* ReportPreview.APP

**2024.03.23 Release**
This release fixes issue #8, a bug in HTML output (thanks to Martina Jindrova).

**2022.08.15 Release**
This release allows the expression in the Print When of a group of objects to have a maximum length of 250 rather than 50 (thanks to creacionesintegrales).

**2022.04.12 Release**
This release fixes a bug in ReportBuilder.app that sometimes causes the data group combobox to contain duplicate items (thanks to Martina Jindrova).

**2021.08.31 Release**
This release fixes a bug in ReportPreview.app that creates the canvas twice (thanks to Christof Wollenhaupt).

**2014.07.04 Release**  
This release fixes a bug in ReportOutput.app and ReportBuilder.app that didn't handle higher DPI displays properly (thanks to Joel Leach).

**2013.03.09 Release**  
This releases fixes a couple of visual bugs in ReportBuilder.APP; see <a href="http://doughennig.blogspot.ca/2013/03/a-couple-more-report-designer-bug-fixes.html" target="_blank">http://doughennig.blogspot.ca/2013/03/a-couple-more-report-designer-bug-fixes.html</a>. It also fixes the "SET TALK" bug described in <a href="http://cathypountney.blogspot.com/2009/04/set-talk-appears-to-be-on-when-running.html" target="_blank">http://cathypountney.blogspot.com/2009/04/set-talk-appears-to-be-on-when-running.html</a>.

**2012.10.30 Release**  
This release fixes two bugs in ReportBuilder.APP. See <a href="http://doughennig.blogspot.ca/2012/09/fixing-another-report-designer-issue.html" target="_blank">http://doughennig.blogspot.ca/2012/09/fixing-another-report-designer-issue.html</a> and <a href="http://doughennig.blogspot.ca/2012/10/fixing-yet-another-report-designer-issue.html" target="_blank">http://doughennig.blogspot.ca/2012/10/fixing-yet-another-report-designer-issue.html</a> for details.

**2012.02.05 Release**  
This release fixes two bugs in ReportBuilder.APP. See <a href="http://doughennig.blogspot.com/2012/02/updating-vfpx-reportbuilderapp.html" target="_blank">http://doughennig.blogspot.com/2012/02/updating-vfpx-reportbuilderapp.html</a> for details.

**2009.05.25 Release**  
This release was about increasing performance. Several changes were made to limit the extra overhead involved when using some of the new SP2 fuctionality (rotation, dynamic colors, etc.). The progress bar was also modified to limit the number of updates. The net result is an increase in output speed from 20% - 400% when using the progress bar or the new "Dynamics" or "Advanced" features on report controls.

ReportOutput performance: Changed Therm bar to update every 0.3 seconds instead of every detail band

Performance: Changed FX and GFX handlers to limit calls to ApplyFX from within Render and EvaluateContents events.

Enhancement: Added oFRX collection property to ReportListener to make it easier to access the underlying report file (ie: This.oFRX(nFRXRecNo).expr )

Reporting Apps is part of [XSource](https://github.com/VFPX/XSource), the source files for various Visual FoxPro components. The license governing XSource can be found in the XSource_EULA.txt included with all of the XSource releases.