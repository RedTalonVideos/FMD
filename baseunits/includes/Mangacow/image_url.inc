  function GetMangaCowImageURL: Boolean;
  var
    s: String;
    j,
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
	s:= DecodeUrl(WebsiteRoots[MANGACOW_ID,1] + URL + IntToStr(workCounter+1));
    Result:= GetPage(TObject(l),
	                 s,
                     manager.container.manager.retryConnect);
    parse:= TStringList.Create;
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;

    if parse.Count>0 then
    begin
      for i:= 0 to parse.Count-1 do
        if (Pos('id="sct_img_mng_enl"', parse.Strings[i])>0) then
        begin
          manager.container.pageLinks.Strings[workCounter]:= EncodeURL(GetAttributeValue(GetTagAttribute(parse.Strings[i], 'src=')));
          break;
        end;
    end;
    parse.Free;
    l.Free;
  end;