xquery version "3.0";

module namespace functx = "http://www.functx.com/functx";


declare function functx:atomic-type
  ( $values as xs:anyAtomicType* )  as xs:string* {

 for $val in $values
 return
 (if ($val instance of xs:untypedAtomic) then 'xs:untypedAtomic'
 else if ($val instance of xs:anyURI) then 'xs:anyURI'
 else if ($val instance of xs:ENTITY) then 'xs:ENTITY'
 else if ($val instance of xs:ID) then 'xs:ID'
 else if ($val instance of xs:NMTOKEN) then 'xs:NMTOKEN'
 else if ($val instance of xs:language) then 'xs:language'
 else if ($val instance of xs:NCName) then 'xs:NCName'
 else if ($val instance of xs:Name) then 'xs:Name'
 else if ($val instance of xs:token) then 'xs:token'
 else if ($val instance of xs:normalizedString)
         then 'xs:normalizedString'
 else if ($val instance of xs:string) then 'xs:string'
 else if ($val instance of xs:QName) then 'xs:QName'
 else if ($val instance of xs:boolean) then 'xs:boolean'
 else if ($val instance of xs:base64Binary) then 'xs:base64Binary'
 else if ($val instance of xs:hexBinary) then 'xs:hexBinary'
 else if ($val instance of xs:byte) then 'xs:byte'
 else if ($val instance of xs:short) then 'xs:short'
 else if ($val instance of xs:int) then 'xs:int'
 else if ($val instance of xs:long) then 'xs:long'
 else if ($val instance of xs:unsignedByte) then 'xs:unsignedByte'
 else if ($val instance of xs:unsignedShort) then 'xs:unsignedShort'
 else if ($val instance of xs:unsignedInt) then 'xs:unsignedInt'
 else if ($val instance of xs:unsignedLong) then 'xs:unsignedLong'
 else if ($val instance of xs:positiveInteger)
         then 'xs:positiveInteger'
 else if ($val instance of xs:nonNegativeInteger)
         then 'xs:nonNegativeInteger'
 else if ($val instance of xs:negativeInteger)
         then 'xs:negativeInteger'
 else if ($val instance of xs:nonPositiveInteger)
         then 'xs:nonPositiveInteger'
 else if ($val instance of xs:integer) then 'xs:integer'
 else if ($val instance of xs:decimal) then 'xs:decimal'
 else if ($val instance of xs:float) then 'xs:float'
 else if ($val instance of xs:double) then 'xs:double'
 else if ($val instance of xs:date) then 'xs:date'
 else if ($val instance of xs:time) then 'xs:time'
 else if ($val instance of xs:dateTime) then 'xs:dateTime'
 else if ($val instance of xs:dayTimeDuration)
         then 'xs:dayTimeDuration'
 else if ($val instance of xs:yearMonthDuration)
         then 'xs:yearMonthDuration'
 else if ($val instance of xs:duration) then 'xs:duration'
 else if ($val instance of xs:gMonth) then 'xs:gMonth'
 else if ($val instance of xs:gYear) then 'xs:gYear'
 else if ($val instance of xs:gYearMonth) then 'xs:gYearMonth'
 else if ($val instance of xs:gDay) then 'xs:gDay'
 else if ($val instance of xs:gMonthDay) then 'xs:gMonthDay'
 else 'unknown')
 } ;

declare function functx:has-empty-content( $element as element() )  as xs:boolean
{
   not($element/node())
 };
 
declare function functx:tknfname($version as xs:string) as xs:int {
    let $v := tokenize($version, "\.") ! number(analyze-string(., "(\d+)")//fn:group[1])
    return
        sum(($v[1] * 1000000, $v[2] * 1000, $v[3]))
};

declare function functx:mark-element($element as element()) as element() {
   element {node-name($element)}
      {$element/@*,
          for $child in $element/node()
              return
               if ($child instance of element(exist:match))
               then <mark>{$child/text()}</mark>
               else 
                   if ($child instance of element())
                   then functx:mark-element($child)
                    else $child
      }
};

declare function functx:mark-attr($element as element()) as element() {
    
    element {node-name($element)}
    
    {$element/@*,
        let $query:= request:get-parameter("query", ())
        let $param:= request:get-parameter("parameter", ())
        let $attr:=substring-after($param, '/@')
        
        for $child in $element/node()
            return
               if ($child instance of element() and $child/@*[local-name(.) = $attr] = $query )
               then <exist:match>{$child/text()}</exist:match>
               else 
                   if ($child instance of element())
                   then functx:mark-attr($child)
                    else $child
    }
};



declare function functx:contains-any-of
  ( $arg as xs:string? ,
    $searchStrings as xs:string* )  as xs:boolean {

   some $searchString in $searchStrings
   satisfies contains($arg,$searchString)
 } ;
 
 declare function functx:number-of-matches 
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer {
       
   count(tokenize(functx:escape-for-regex(functx:escape-for-regex($arg)),functx:escape-for-regex($pattern))) - 1
 } ;

declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;
 
 declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {

   $value = $seq
 } ;
 
 
 (:~
    Callback function called from the kwic module.
:)
declare function functx:filter($node as node(), $mode as xs:string) as xs:string? {
   if ($mode eq 'before') then 
      concat($node, ' ')
  else 
      concat(' ', $node)
};

declare function functx:replace-multi
  ( $arg as xs:string? ,
    $changeFrom as xs:string* ,
    $changeTo as xs:string* )  as xs:string? {

   if (count($changeFrom) > 0)
   then functx:replace-multi(
          replace($arg, $changeFrom[1],
                     functx:if-absent($changeTo[1],'')),
          $changeFrom[position() > 1],
          $changeTo[position() > 1])
   else $arg
 } ;
 
 declare function functx:if-absent
  ( $arg as item()* ,
    $value as item()* )  as item()* {

    if (exists($arg))
    then $arg
    else $value
 } ;
 
 
 declare function functx:sanitize-string ($arg as xs:string?) {
    let $changeFrom:=('AND','OR','NOT','\+','\-','!','~','\^','\.','\|','\{','\[','\(','<','@','#','&amp;')
    let $string:=
        if (count($changeFrom) > 0)
        then functx:replace-multi(replace($arg, $changeFrom[1],''),$changeFrom[position() > 1],'')
        else $arg
    return
        $string
 } ;
 
 declare function functx:get-matches
  ( $string as xs:string? ,
    $regex as xs:string )  as xs:string* {

   functx:get-matches-and-non-matches($string,$regex)/
     string(self::match)
 } ;
    
 declare function functx:get-matches-and-non-matches
  ( $string as xs:string? ,
    $regex as xs:string )  as element()* {

   let $iomf := functx:index-of-match-first($string, $regex)
   return
   if (empty($iomf))
   then <non-match>{$string}</non-match>
   else
   if ($iomf > 1)
   then (<non-match>{substring($string,1,$iomf - 1)}</non-match>,
         functx:get-matches-and-non-matches(
            substring($string,$iomf),$regex))
   else
   let $length :=
      string-length($string) -
      string-length(functx:replace-first($string, $regex,''))
   return (<match>{substring($string,1,$length)}</match>,
           if (string-length($string) > $length)
           then functx:get-matches-and-non-matches(
              substring($string,$length + 1),$regex)
           else ())
 } ;
 
 declare function functx:replace-first
  ( $arg as xs:string? ,
    $pattern as xs:string ,
    $replacement as xs:string )  as xs:string {

   replace($arg, concat('(^.*?)', $pattern),
             concat('$1',$replacement))
 } ;
 
 declare function functx:index-of-match-first
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer? {

  if (matches($arg,$pattern))
  then string-length(tokenize($arg, $pattern)[1]) + 1
  else ()
 } ;
 
 declare function functx:last-node
  ( $nodes as node()* )  as node()? {

   ($nodes/.)[last()]
 }; 
 
 declare function functx:sort-as-numeric
  ( $seq as item()* )  as item()* {

   for $item in $seq
   order by number($item)
   return $item
 } ;
 
 declare function functx:namespaces-in-use
  ( $root as node()? )  as xs:anyURI* {

   distinct-values(
      $root/descendant-or-self::*/(.|@*)/namespace-uri(.))
 } ;
 
 declare function functx:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;
 

 
 declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {

   $value = $seq
 };
 
 declare function functx:if-empty
  ( $arg as item()? ,
    $value as item()* )  as item()* {

  if (string($arg) != '')
  then data($arg)
  else $value
 } ;