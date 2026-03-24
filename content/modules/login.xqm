xquery version "3.1";

(:~
 : Login/logout handler module.
 :
 : Provides session-based authentication functions used by the
 : controller and templates.
 :)
module namespace login = "http://exist-db.org/site/login";

(:~
 : Get the current authenticated user, or "guest" if not logged in.
 :
 : @return the username string
 :)
declare function login:current-user() as xs:string {
    let $session-user := session:get-attribute("user")
    return
        if (exists($session-user) and $session-user != "") then
            $session-user
        else
            sm:id()//sm:real/sm:username/string()
};

(:~
 : Check whether the current user is authenticated (not guest).
 :
 : @return true if logged in
 :)
declare function login:is-logged-in() as xs:boolean {
    login:current-user() != "guest"
};
