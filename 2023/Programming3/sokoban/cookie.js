  function SetCookie(Name, Val)
  {
    window.localStorage[Name] = Val;
  }
  function ResetCookie(Name)
  {
    SetCookie(Name, 0);
  }
  function GetCookie(Name)
  {
    CookiesGetted = window.localStorage[Name];
  }

/*
  // programmed by gabonator.Atlas.cz
  CookiesGetted = -1;
  function SetCookie(Name, Val)
  {
    expires=new Date();
    expires.setTime (expires.getTime() + 86400000);
    document.cookie= escape('Gabonator'+Name) + '=' + escape(Val) + '; expires=' + expires.toGMTString() + '; path=/';
    document.cookie= escape('Gabonator'+Name) + '=' + escape(Val) + '; expires=' + expires.toGMTString() + '; path=/; domain=gabonator.szm.sk';
  }
  function ResetCookie(Name)
  {
    SetCookie(Name, 0);
  }
  function GetCookie(Name)
  {
    CookiesGetted=-1;
    var search = "Gabonator"+Name+"=";
    if (document.cookie.length > 0) {
      offset = document.cookie.indexOf(search)
      if (offset != -1) { 
        offset += search.length
        end = document.cookie.indexOf(";", offset)
        if (end == -1)
          end = document.cookie.length;
        CookiesGetted = unescape(document.cookie.substring(offset, end));
      }
    }
  }
*/