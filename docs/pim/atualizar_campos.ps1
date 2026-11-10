
param([string]$Docx, [string]$Pdf)
$ErrorActionPreference = "Stop"
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
  $doc = $word.Documents.Open($Docx, $false, $false)
  # Estilos internos do Word para sumário (toc 1-3 = -20..-22) e índice de ilustrações (-36)
  foreach ($id in -20, -21, -22, -36) {
    $st = $doc.Styles.Item($id)
    $pf = $st.ParagraphFormat
    $pf.LeftIndent = 0; $pf.FirstLineIndent = 0; $pf.RightIndent = 0
    $pf.Alignment = 0; $pf.SpaceBefore = 0; $pf.SpaceAfter = 0; $pf.LineSpacingRule = 1
    $st.Font.Name = "Arial"; $st.Font.Size = 12; $st.Font.Bold = [int]($id -eq -20)
    Write-Output ("ESTILO " + $id + " = " + $st.NameLocal)
  }
  $doc.Repaginate()
  $doc.Fields.Update() | Out-Null
  foreach ($t in $doc.TablesOfContents) { $t.Update() }
  $doc.Repaginate()
  foreach ($t in $doc.TablesOfContents) { $t.UpdatePageNumbers() }
  foreach ($t in $doc.TablesOfContents) { $t.Range.Font.Name = "Arial" }
  foreach ($sec in $doc.Sections) {
    foreach ($h in $sec.Headers) { $h.Range.Font.Name = "Arial"; $h.Range.Font.Size = 10 }
  }
  $doc.Save()
  $doc.ExportAsFixedFormat($Pdf, 17)
  Write-Output ("PAGINAS=" + $doc.ComputeStatistics(2))
  $doc.Close($false)
} finally { $word.Quit() }
