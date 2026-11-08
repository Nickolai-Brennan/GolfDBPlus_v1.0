---
hide:
  - navigation
---

<div class="landing-hero">
  <div class="hero-copy">
    <p class="eyebrow"><span class="live-dot"></span> OPEN DATA FIELD GUIDE · 2026</p>
    <h1>Every shot.<br><em>Every stat.</em><br>One Python client.</h1>
    <p class="hero-lede">Explore the data behind the tour: live leaderboards, player profiles, shot tracking, course stats and more, through a practical Python interface.</p>
    <div class="hero-actions">
      <a class="hero-button" href="getting-started/">Get started <span>↗</span></a>
      <a class="hero-link" href="endpoints/">Browse endpoints <span>→</span></a>
    </div>
  </div>
  <div class="hero-card">
    <div class="scorecard-top"><span>QUICK START</span><span class="pill">PYTHON</span></div>
    <pre><code>import pga_tour_api as pga

# Find this week's event
event = pga.pga_current_tournament()

# Pull the leaderboard
field = pga.pga_leaderboard(event)

# Explore shot-by-shot data
shots = pga.pga_shot_details(
    event, "34046", round=1
)</code></pre>
    <div class="scorecard-foot"><span><i></i> Ready for your notebook</span><span>01 / 03</span></div>
  </div>
</div>

<div class="trust-strip">
  <span><b>42</b> GraphQL operations</span><span><b>54</b> Python functions</span><span><b>467</b> stat IDs</span><span><b>4</b> tour codes</span>
</div>

## Find your line

<div class="path-grid">
  <a class="path-card" href="getting-started/"><span class="path-index">01 / START</span><strong>Make your first call</strong><span>Install the client and pull a live leaderboard in a few lines.</span><b class="path-arrow">↗</b></a>
  <a class="path-card" href="dataframe-api/"><span class="path-index">02 / EXPLORE</span><strong>Work with the data</strong><span>Browse the normalized functions and their return columns.</span><b class="path-arrow">↗</b></a>
  <a class="path-card" href="endpoints/"><span class="path-index">03 / UNDER THE HOOD</span><strong>Inspect the endpoints</strong><span>See routes, operations, variables and response handling.</span><b class="path-arrow">↗</b></a>
</div>

## Pick a data route

<div class="data-grid">
  <div class="data-card"><span class="data-icon">01</span><h3>Follow the tournament</h3><p>Leaderboards, tee times, fields, scorecards and shot-by-shot tracking.</p><a href="dataframe-api/">Live tournament functions →</a></div>
  <div class="data-card"><span class="data-icon">02</span><h3>Know the players</h3><p>Profiles, career results, player stats and season rankings.</p><a href="data-models/">Explore return schemas →</a></div>
  <div class="data-card"><span class="data-icon">03</span><h3>Read the course</h3><p>Course information, hole scoring, weather and course-fit stats.</p><a href="stats-catalog/">Browse the stats catalog →</a></div>
</div>

## Two ways to work

<div class="interface-row"><div><span class="path-index">THE FRIENDLY LAYER</span><h3>DataFrames for analysis</h3><p>Use the <code>pga_*</code> helpers for analysis. Most return tidy pandas tables; seven return a string, dictionary, or raw JSON.</p><a href="dataframe-api/">See the Python API →</a></div><div><span class="path-index">THE RAW LAYER</span><h3>Responses as delivered</h3><p>Use <code>PgaApi</code> when you need the original response structure or want to work closer to the source.</p><a href="python-client/">See the raw client →</a></div></div>

!!! warning "Unofficial interface"
    PGA TOUR does not document or support these endpoints. Routes and fields can change without notice. This project is independent and is not affiliated with or endorsed by PGA TOUR. Use responsibly, cache historical data, and follow the site's terms and robots.txt.
