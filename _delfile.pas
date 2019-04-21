unit _DelFile;

interface
uses StrUtils,SysUtils,PerlRegEx,Classes,Windows;
function LastPos(const SubStr, Str: string): Integer;
//function  searchfile(var List:TStringList;path:string;sfile:string='*.*';iflag:Integer =0):Boolean;
implementation
function StringTrimRight(S:string;Count:Integer):string ;
begin
StringTrimRight:=Copy(s,1,Length(s)-count);
end;

function LastPos(const SubStr, Str: string): Integer;
var
  Idx: Integer; // an index of SubStr in Str
begin
  Result := 0;
  Idx := StrUtils.PosEx(SubStr, Str);
  if Idx = 0 then
    Exit;
  while Idx > 0 do
  begin
    Result := Idx;
    Idx := StrUtils.PosEx(SubStr, Str, Idx + 1);
  end;
end;

function StringTrimLeft(S:string;Count:Integer):string ;
begin
StringTrimLeft:=Copy(s,count+1,Length(s)-Count);
end;

function StringInStr(const sub:string;s:string):Integer ;
var
  Buff:Integer;
begin
  Buff:=PosEx(sub,s,1);
  Result:=Buff;
  while Buff>0 do
  begin
    buff:=PosEx(sub,s,buff+1);
    if Buff >0 then Result:=Buff;
  end;
  end;





function  searchfile(var List:TStringList;path:string;sfile:string ='*.*';iflag:Integer=0):Boolean;//注意,path后面要有'\';
   var
       SearchRec:TSearchRec;
       found:integer;
   begin
       //List:=TStringList.Create;
       found:=FindFirst(path+sfile,faAnyFile,SearchRec);
       while found=0    do
         begin
              if (SearchRec.Name<>'.') and (SearchRec.name<>'..') then
               begin

               if iflag =0 then
               begin
                 //if ((SearchRec.Attr and faDirectory) <> 16) then
                 //begin
                 List.Add(Path+SearchRec.Name);
                 //SearchFile(List,path + SearchRec.Name + '\');
                // end;
                // List.Add(Path+SearchRec.Name);
                //if not DeleteFile(PAnsiChar(Path+SearchRec.Name)) then Result:=True;
               end;
                if iflag =2 then
               begin
                 if ((SearchRec.Attr and faDirectory) <> 0) then
                 begin
                 List.Add(Path+SearchRec.Name);
                 SearchFile(List,path + SearchRec.Name + '\');
                 end
               end;
               if iflag =1 then
               begin
                  if not ((SearchRec.Attr and faDirectory) <> 0) then
                  List.Add(Path+SearchRec.Name);
               end;

           end;


              found:=FindNext(SearchRec);   
         end;
       SysUtils.FindClose(SearchRec);
   end;




end.
