#!/bin/sh
# Geometry and contract checks for a cistina-arch SVG fragment.
# POSIX sh + awk only (no Python/Node required).
#
# Usage: check.sh diagram.svg
#
# Checks: node kinds, duplicate ids, node box overlap (min 8px clear gap),
# edge from/to referencing existing data-node-id, edge endpoints touching the
# node boxes (12px tolerance; vertical lifeline hits are allowed for sequence
# diagrams), loose labels overlapping nodes, and --step presence when
# data-animation="trace" is enabled.
# Exit 0 = OK, 1 = errors found.

set -u

[ $# -eq 1 ] || { echo "usage: check.sh diagram.svg" >&2; exit 2; }
[ -f "$1" ] || { echo "error: file not found: $1" >&2; exit 2; }

awk -v RS='>' '
function getattr(tag, name,   pat, i, rest, j) {
  pat = " " name "=\""
  i = index(tag, pat)
  if (i == 0) return ""
  rest = substr(tag, i + length(pat))
  j = index(rest, "\"")
  if (j == 0) return ""
  return substr(rest, 1, j - 1)
}
function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }
function mn(a, b) { return a < b ? a : b }
function mx(a, b) { return a > b ? a : b }
# Clear gap between two boxes; negative when they overlap.
function ovgap(ax, ay, ax2, ay2, bx, by, bx2, by2,   dx, dy, ox, oy) {
  dx = mx(mx(ax, bx) - mn(ax2, bx2), 0)
  dy = mx(mx(ay, by) - mn(ay2, by2), 0)
  if (dx == 0 && dy == 0) {
    ox = mn(ax2, bx2) - mx(ax, bx)
    oy = mn(ay2, by2) - mx(ay, by)
    return -mn(ox, oy)
  }
  if (dx == 0) return dy
  if (dy == 0) return dx
  return sqrt(dx * dx + dy * dy)
}
function nearbox(px, py, i,   cx, cy, ddx, ddy) {
  cx = mn(mx(px, nx[i]), nx2[i]); cy = mn(mx(py, ny[i]), ny2[i])
  ddx = px - cx; ddy = py - cy
  return (ddx * ddx + ddy * ddy) <= TOL * TOL
}
# Sequence-style hit: endpoint sits on the vertical lifeline under/above the box.
function lifeline(px, py, i) {
  return (px >= nx[i] - TOL && px <= nx2[i] + TOL) && (py > ny2[i] + TOL || py < ny[i] - TOL)
}
function dends(d,   s, n, a) {
  s = d
  gsub(/[^0-9.\-]/, " ", s)
  n = split(s, a, /[ \t]+/)
  # drop empty leading token from split
  while (n > 0 && a[1] == "") { for (i = 1; i < n; i++) a[i] = a[i + 1]; n-- }
  if (n < 4) return 0
  ex1 = a[1] + 0; ey1 = a[2] + 0; ex2 = a[n - 1] + 0; ey2 = a[n] + 0
  return 1
}
function stepof(tag,   st, i, rest) {
  st = getattr(tag, "style")
  i = index(st, "--step")
  if (i == 0) return "none"
  rest = substr(st, i + 6)
  sub(/^[: \t]+/, "", rest)
  sub(/[^0-9.\-].*$/, "", rest)
  return rest == "" ? "none" : rest
}
function err(msg) { E[++ne] = msg }
function warn(msg) { W[++nw] = msg }

BEGIN {
  KINDS = " frontend backend database cloud security messagebus external "
  TOL = 12; GAP = 8
  nn = 0; nedge = 0; ne = 0; nw = 0; nlab = 0
  nodeId = ""; nodeDepth = 0; edgeOpen = 0; edgeDepth = 0
  svgAnim = ""; pendText = 0
}
{
  rec = $0
  gsub(/[\r\n\t]/, " ", rec)
  ci = index(rec, "<")
  pre = ci > 1 ? substr(rec, 1, ci - 1) : ""
  tag = ci > 0 ? substr(rec, ci) : ""
  if (tag == "") next

  # text content belongs to the immediately preceding <text> element
  if (pendText && index(tag, "</text") == 1) {
    content = trim(pre)
    if (content != "" && pendInNode == 0) {
      nlab++
      labx[nlab] = pendX; laby[nlab] = pendY; labt[nlab] = content
    }
    pendText = 0
  }

  if (index(tag, "<svg") == 1) {
    svgAnim = getattr(tag, "data-animation")
    next
  }

  if (index(tag, "</g") == 1) {
    if (edgeOpen) { edgeDepth--; if (edgeDepth <= 0) edgeOpen = 0 }
    else if (nodeId != "") { nodeDepth--; if (nodeDepth <= 0) nodeId = "" }
    next
  }

  if (index(tag, "<g") == 1) {
    nid = getattr(tag, "data-node-id")
    efrom = getattr(tag, "data-edge-from")
    if (nid != "") {
      nn++
      id[nn] = nid; kind[nn] = getattr(tag, "data-node-kind")
      nx[nn] = ""; hasTyped[nn] = 0
      nodeId = nid; nodeIdx = nn; nodeDepth = 1
      nodeAnim[nn] = 0; nodeStep[nn] = "none"
      if (nid in seen) err("duplicate data-node-id=" nid)
      seen[nid] = nn
      if (index(KINDS, " " kind[nn] " ") == 0)
        err("node " nid ": data-node-kind=\"" kind[nn] "\" invalid")
    } else if (efrom != "") {
      nedge++
      eid[nedge] = getattr(tag, "data-edge-id"); efr[nedge] = efrom
      eto[nedge] = getattr(tag, "data-edge-to")
      if (eid[nedge] == "") eid[nedge] = efrom "->" eto[nedge]
      ed[nedge] = ""; eAnim[nedge] = 0; eStep[nedge] = "none"
      edgeOpen = 1; edgeIdx = nedge; edgeDepth = 1
    } else if (nodeId != "") nodeDepth++
    else if (edgeOpen) edgeDepth++
    next
  }

  isPath = (index(tag, "<path") == 1 || index(tag, "<line") == 1)
  if (isPath) {
    efrom = getattr(tag, "data-edge-from")
    d = getattr(tag, "d")
    if (index(tag, "<line") == 1 && d == "")
      d = "M " getattr(tag, "x1") " " getattr(tag, "y1") " L " getattr(tag, "x2") " " getattr(tag, "y2")
    if (efrom != "") {
      nedge++
      eid[nedge] = getattr(tag, "data-edge-id"); efr[nedge] = efrom
      eto[nedge] = getattr(tag, "data-edge-to")
      if (eid[nedge] == "") eid[nedge] = efrom "->" eto[nedge]
      ed[nedge] = d
      eAnim[nedge] = (getattr(tag, "data-animate") != "")
      eStep[nedge] = stepof(tag)
    } else if (edgeOpen && ed[edgeIdx] == "" && d != "") {
      ed[edgeIdx] = d
      if (getattr(tag, "data-animate") != "") {
        eAnim[edgeIdx] = 1; eStep[edgeIdx] = stepof(tag)
      }
    }
    next
  }

  if (index(tag, "<rect") == 1) {
    if (nodeId != "") {
      cls = getattr(tag, "class")
      typed = (cls ~ /c-(frontend|backend|database|cloud|security|messagebus|external)/)
      if (typed || nx[nodeIdx] == "") {
        nx[nodeIdx] = getattr(tag, "x") + 0
        ny[nodeIdx] = getattr(tag, "y") + 0
        nx2[nodeIdx] = nx[nodeIdx] + getattr(tag, "width")
        ny2[nodeIdx] = ny[nodeIdx] + getattr(tag, "height")
        if (typed) hasTyped[nodeIdx] = 1
      }
      if (getattr(tag, "data-animate") != "") {
        nodeAnim[nodeIdx] = 1; nodeStep[nodeIdx] = stepof(tag)
      }
    }
    next
  }

  if (index(tag, "<text") == 1) {
    pendText = 1
    pendX = getattr(tag, "x") + 0; pendY = getattr(tag, "y") + 0
    pendInNode = (nodeId != "") ? 1 : 0
    next
  }
}
END {
  if (nn == 0) err("no nodes with data-node-id")
  for (i = 1; i <= nn; i++)
    if (nx[i] == "" || nx2[i] <= nx[i] || ny2[i] <= ny[i])
      err("node " id[i] ": empty box")

  for (i = 1; i <= nn; i++)
    for (j = i + 1; j <= nn; j++) {
      if (nx[i] == "" || nx[j] == "") continue
      g = ovgap(nx[i], ny[i], nx2[i], ny2[i], nx[j], ny[j], nx2[j], ny2[j])
      if (g < GAP)
        err(sprintf("overlap %s vs %s: gap %.1fpx (min %d)", id[i], id[j], g, GAP))
    }

  for (k = 1; k <= nedge; k++) {
    if (!(efr[k] in seen)) err("edge " eid[k] ": data-edge-from=\"" efr[k] "\" missing node")
    if (!(eto[k] in seen)) err("edge " eid[k] ": data-edge-to=\"" eto[k] "\" missing node")
    if (ed[k] == "") { warn("edge " eid[k] ": no path geometry"); continue }
    if (!dends(ed[k])) continue
    if (efr[k] in seen) {
      i = seen[efr[k]]
      if (nx[i] != "" && !nearbox(ex1, ey1, i) && !lifeline(ex1, ey1, i))
        err(sprintf("edge %s: start (%g, %g) not on node %s", eid[k], ex1, ey1, efr[k]))
    }
    if (eto[k] in seen) {
      i = seen[eto[k]]
      if (nx[i] != "" && !nearbox(ex2, ey2, i) && !lifeline(ex2, ey2, i))
        err(sprintf("edge %s: end (%g, %g) not on node %s", eid[k], ex2, ey2, eto[k]))
    }
  }

  for (l = 1; l <= nlab; l++) {
    w = length(labt[l]) * 5.5; if (w < 24) w = 24
    lx = labx[l] - w / 2; ly = laby[l] - 10
    for (i = 1; i <= nn; i++) {
      if (nx[i] == "") continue
      if (ovgap(lx, ly, lx + w, ly + 14, nx[i], ny[i], nx2[i], ny2[i]) < 0)
        warn("label \"" labt[l] "\" overlaps node " id[i])
    }
  }

  if (svgAnim == "trace") {
    animated = 0; hasZero = 0
    for (i = 1; i <= nn; i++) if (nodeAnim[i]) {
      animated++
      if (nodeStep[i] == "none") err(id[i] ": data-animate without --step")
      else if (nodeStep[i] + 0 == 0) hasZero = 1
    }
    for (k = 1; k <= nedge; k++) if (eAnim[k]) {
      animated++
      if (eStep[k] == "none") err(eid[k] ": data-animate without --step")
      else if (eStep[k] + 0 == 0) hasZero = 1
    }
    if (animated == 0) err("data-animation=trace but no data-animate nodes/edges")
    else if (!hasZero) warn("trace --step sequence does not start at 0")
  }

  for (i = 1; i <= ne; i++) print "FAIL " E[i]
  for (i = 1; i <= nw; i++) print "WARN " W[i]
  if (ne > 0) {
    printf "%d error(s), %d warning(s), %d nodes, %d edges\n", ne, nw, nn, nedge
    exit 1
  }
  printf "OK %d nodes, %d edges, %d warning(s)\n", nn, nedge, nw
}
' "$1"
