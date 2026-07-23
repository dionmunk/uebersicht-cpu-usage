command: "cpu-usage.widget/lib/cputick.sh"

refreshFrequency: '1s'

# Toggle the graph panel on/off without removing the widget
showGraph: false

# Set to true to show emoji faces instead of a colored dot for thermal state
useEmoji: true

throttleEmoji:
  none: '\u{1F600}'        # 😀 grinning
  light: '\u{1F605}'       # 😅 grinning with sweat
  noticeable: '\u{1F630}'  # 😰 anxious
  severe: '\u{1F975}'      # 🥵 hot

historyLength: 60  # 1 min @ 1s refresh

history: []

style: """
  // grid: col 1 · row 1 · 1×1  (see LAYOUT.md)
  top 10px
  left 10px

  color var(--text, #fff)
  text-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)   // inherits to all text elements
  font-family -apple-system, BlinkMacSystemFont, system-ui, sans-serif
  display: flex
  gap: 10px

  .panel
    background var(--panel-bg, rgba(#000, .15))
    border-radius 10px
    -webkit-backdrop-filter: blur(var(--panel-blur, 48px))
    backdrop-filter: blur(var(--panel-blur, 48px))
    box-sizing: border-box
    min-height: 80px       // base minimum widget height (see LAYOUT.md)

  .panel-stats
    padding 9px 10px 12px
    display: flex          // lets stats-inner fill the 80px panel height

  .panel-graph
    padding 10px

  .stats-inner
    width: 300px
    text-align: left
    position: relative
    display: flex
    flex-direction: column   // title on top, numbers + bar pushed to the bottom

  .widget-title
    font-size 10px
    line-height: 10px
    text-transform uppercase
    font-weight bold
    position: relative
    margin-bottom: 1px

  .throttle-dot
    position: absolute
    top: 50%
    right: 0
    transform: translateY(-50%)
    width: 8px
    height: 8px
    border-radius: 50%
    background: var(--secondary, rgba(#ccc, .5))
    transition: background 1.5s ease
    box-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)   // matches text shadow

  .throttle-dot.throttle-emoji
    display: block
    width: auto
    height: auto
    border-radius: 0
    background: transparent
    box-shadow: none

  .throttle-glyph
    position: absolute
    top: -5px
    right: 0
    font-size: 10px
    line-height: 1
    pointer-events: none
    transition: opacity 1.5s ease

  // Thermal state → status roles. Under apple: green/yellow/orange/red. Under
  // monochrome (--status-* unset) each falls through to the matching --level-*
  // neutral (ink opacity ramp .4/.6/.8/1), which flips with light/dark mode.
  .throttle-none
    background: var(--status-ok, var(--level-lo, rgba(#fff, .4)))

  .throttle-light
    background: var(--status-warn, var(--level-mid, rgba(#fff, .6)))

  .throttle-noticeable
    background: var(--status-elevated, var(--level-hi, rgba(#fff, .8)))

  .throttle-severe
    background: var(--status-critical, var(--level-max, rgba(#fff, 1)))

  .throttle-emoji.throttle-none,
  .throttle-emoji.throttle-light,
  .throttle-emoji.throttle-noticeable,
  .throttle-emoji.throttle-severe
    background: transparent

  .stats-container
    margin-top: auto       // push the numbers + bar to the panel bottom
    margin-bottom 5px      // gap between the labels and the bar
    border-collapse collapse
    table-layout: fixed

  td
    font-size: 14px
    font-weight: 300
    text-align: left
    width: 25%

  // Throttle is the last column — right-align its value and label.
  td:last-child
    text-align: right

  // Space between the numbers and their labels below them.
  .stat
    padding-bottom: 4px

  .label
    font-size 8px
    text-transform uppercase
    font-weight bold

  .bar-container
    width: 100%
    height: 6px
    border-radius: 6px
    background: var(--level-base, rgba(#fff, .2))
    position: relative
    box-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)   // base bar: matches text shadow

  // Each series is its own independent layer: anchored at the left, drawn to its
  // *cumulative* width, and stacked smallest-on-top. So the lower series fill the
  // whole area behind the upper one instead of being tacked onto its right end —
  // an opaque top layer cleanly covers the overlap (no compounding transparency).
  .bar
    position: absolute
    left: 0
    top: 0
    height: 6px
    border-radius: 6px
    transition: width .2s ease-in-out
    box-shadow: 1px 0 3px rgba(0, 0, 0, 0.04)   // faint separation under the cap

  .bar:nth-child(1)
    z-index: 5
  .bar:nth-child(2)
    z-index: 4
  .bar:nth-child(3)
    z-index: 3
  .bar:nth-child(4)
    z-index: 2

  .bar-sys
    background: var(--series-secondary, rgba(#fff, .5))

  .bar-user
    background: var(--series-primary, rgba(#fff, 1))

  .graph-container
    width: 300px
    height: 53px
    position: relative
    overflow: hidden
    border: 1px solid var(--hairline, rgba(#ccc, .125))
    border-radius: 3px
    box-sizing: border-box
    padding: 1px
    background-image: radial-gradient(var(--dot-grid, rgba(#fff, .05)) 1px, transparent 1.5px)
    background-size: 10px 10px
    background-position: -4px -4px

  svg
    display: block
    width: 100%
    height: 100%

  .line-user
    fill: none
    stroke: var(--series-primary, rgba(#fff, 1))
    stroke-width: 1.5
    vector-effect: non-scaling-stroke
    stroke-linejoin: round
    stroke-linecap: round

  .line-sys
    fill: none
    stroke: var(--series-secondary, rgba(#fff, .5))
    stroke-width: 1.5
    vector-effect: non-scaling-stroke
    stroke-linejoin: round
    stroke-linecap: round

  .area-user
    fill: var(--series-primary-fill, rgba(#fff, .3))
    stroke: none

  .area-sys
    fill: var(--series-secondary-fill, rgba(#fff, .15))
    stroke: none
"""

render: -> """
  <div class="panel panel-stats">
    <div class="stats-inner">
      <div class="widget-title">CPU<span class="throttle-dot" title=""></span></div>
      <table class="stats-container" width="100%">
        <tr>
          <td class="stat"><span class="user"></span></td>
          <td class="stat"><span class="sys"></span></td>
          <td class="stat"><span class="idle"></span></td>
          <td class="stat"><span class="throttle"></span></td>
        </tr>
        <tr>
          <td class="label">user</td>
          <td class="label">sys</td>
          <td class="label">idle</td>
          <td class="label">throttle</td>
        </tr>
      </table>
      <div class="bar-container">
        <div class="bar bar-user"></div>
        <div class="bar bar-sys"></div>
      </div>
    </div>
  </div>
  #{if @showGraph then """
  <div class="panel panel-graph">
    <div class="graph-container">
      <svg preserveAspectRatio="none" viewBox="0 0 59 100">
        <polygon class="area-user" points=""></polygon>
        <polygon class="area-sys" points=""></polygon>
        <polyline class="line-user" points=""></polyline>
        <polyline class="line-sys" points=""></polyline>
      </svg>
    </div>
  </div>
  """ else ""}
"""

update: (output, domEl) ->
  parts = output.trim().split /\s+/
  ticks =
    user:   Number(parts[0])
    system: Number(parts[1])
    idle:   Number(parts[2])
    nice:   Number(parts[3])
  kernelCpu = Number(parts[4]) or 0
  return unless isFinite(ticks.user) and isFinite(ticks.system) and isFinite(ticks.idle)

  unless @prev
    @prev = ticks
    return

  dUser = ticks.user   - @prev.user
  dSys  = ticks.system - @prev.system
  dIdle = ticks.idle   - @prev.idle
  dNice = ticks.nice   - @prev.nice
  @prev = ticks

  total = dUser + dSys + dIdle + dNice
  return if total <= 0

  userPct = (dUser + dNice) / total * 100
  sysPct  = dSys / total * 100
  idlePct = dIdle / total * 100

  updateStat = (sel, value) ->
    $(domEl).find(".#{sel}").text value.toFixed(2)

  updateStat 'user', userPct
  updateStat 'sys',  sysPct
  updateStat 'idle', idlePct

  # Bars are independent cumulative layers: user on top (0→user), user+sys behind
  # it (0→user+sys) so the sys shade fills the area beyond the user bar.
  $(domEl).find('.bar-user').css 'width', "#{userPct}%"
  $(domEl).find('.bar-sys').css  'width', "#{userPct + sysPct}%"

  $(domEl).find('.throttle').text kernelCpu.toFixed(2)

  [throttleClass, throttleLabel] =
    if kernelCpu >= 60 then ['throttle-severe', 'severe']
    else if kernelCpu >= 40 then ['throttle-noticeable', 'noticeable']
    else if kernelCpu >= 20 then ['throttle-light', 'light']
    else ['throttle-none', 'none']

  $dot = $(domEl).find('.throttle-dot')
    .attr 'title', "throttle: #{throttleLabel} (kernel_task #{kernelCpu.toFixed(1)}%)"
    .removeClass('throttle-none throttle-light throttle-noticeable throttle-severe')
    .addClass(throttleClass)

  if @useEmoji
    $dot.addClass('throttle-emoji')
    if @prevThrottleLabel isnt throttleLabel
      $existing = $dot.find('.throttle-glyph')
      initial = $existing.length is 0
      $newGlyph = $('<span class="throttle-glyph"></span>')
        .text(@throttleEmoji[throttleLabel])
        .css('opacity', if initial then 1 else 0)
        .appendTo($dot)
      unless initial
        # Force reflow so the opacity transition runs from 0 → 1.
        $newGlyph[0].offsetWidth
        $newGlyph.css('opacity', 1)
        $existing.css('opacity', 0)
        do ($existing) ->
          setTimeout (-> $existing.remove()), 1500
  else
    $dot.removeClass('throttle-emoji').find('.throttle-glyph').remove()

  @prevThrottleLabel = throttleLabel

  return unless @showGraph

  @history ?= []
  @history.push {user: userPct, sys: sysPct}
  @history.shift() while @history.length > @historyLength

  return if @history.length < 2

  N = @historyLength
  offset = N - 1 - (@history.length - 1)
  lastX = offset + @history.length - 1

  # Stacked area chart:
  #   pink user area runs from baseline (y=100) up to the user line
  #   green sys area is the strip from user line up to user+sys line
  userLinePts = @history.map((s, i) -> "#{offset + i},#{100 - s.user}").join(" ")
  sysLinePts  = @history.map((s, i) -> "#{offset + i},#{100 - s.user - s.sys}").join(" ")
  userLineReversed = @history.map((s, i) -> "#{offset + i},#{100 - s.user}").reverse().join(" ")

  $(domEl).find('.line-user').attr('points', userLinePts)
  $(domEl).find('.line-sys').attr('points', sysLinePts)
  $(domEl).find('.area-user').attr('points', "#{userLinePts} #{lastX},100 #{offset},100")
  $(domEl).find('.area-sys').attr('points', "#{sysLinePts} #{userLineReversed}")
