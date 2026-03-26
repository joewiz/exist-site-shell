<div class="apps-page">
    <h1>Installed Applications</h1>
    <div class="app-grid">
        [% for $app in $launcher-apps?* %]
        <a href="[[ $app?url ]]" class="app-card">
            [% if $app?icon != '' %]
            <img src="[[ $app?icon ]]" alt="" class="app-icon"/>
            [% else %]
            <div class="app-icon app-icon-placeholder">[[ substring($app?title, 1, 1) ]]</div>
            [% endif %]
            <h2>[[ $app?title ]]</h2>
            <p>[[ $app?description ]]</p>
        </a>
        [% endfor %]
    </div>
</div>
