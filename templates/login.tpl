---json
{
    "templating": {
        "extends": "templates/base-page.tpl"
    }
}
---
[% template title %]Login -- [[ $site-name ]][% endtemplate %]

[% template content %]
<div class="login-page">
    <h1>Login</h1>

    [% if exists($login-error) %]
    <div class="login-error" role="alert">
        [[ $login-error ]]
    </div>
    [% endif %]

    <form class="login-form" method="post" action="[[ $shell-base ]]/login">
        <div class="form-field">
            <label for="login-user">Username</label>
            <input type="text" id="login-user" name="user" required="" autocomplete="username"/>
        </div>
        <div class="form-field">
            <label for="login-password">Password</label>
            <input type="password" id="login-password" name="password" autocomplete="current-password"/>
        </div>
        <button type="submit">Login</button>
    </form>
</div>
[% endtemplate %]
