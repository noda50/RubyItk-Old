#! /usr/bin/env ruby
## -*- Mode: ruby -*-

$LOAD_PATH.push("~/lib/ruby") ;

require 'rexml/document' ;
module XML
  include REXML
end

require 'Geo2DGml.rb' ;

module ItkXml

  ##----------------------------------------------------------------------
  ## namespace utility

  NameSpaceTable = {
    :soap  => ['SOAP-ENV','http://schemas.xmlsoap.org/soap/envelope/'],
    :gml   => ['gml',     'http://www.opengis.net/gml'],
    :xlink => ['xlink',	  'http://www.w3.org/1999/xlink'],
    :xsd   => ['xsd',	  'http://www.w3.org/2001/XMLSchema'],
    nil   => nil } ;

  ## table for XPath
  NameSpaceHash = {} ;
  NameSpaceTable.each{|key,value|
    (prefix,uri) = value ;
    NameSpaceHash[prefix] = uri;
  }

  def defaultNameSpaceTable
    return NameSpaceTable ;
  end

  ##--------------------------------------------------
  def copyNameSpace(table = NameSpaceTable)
    newTable = {} ;
    table.each{|key, value|
      newTable[key] = value ;
    }
  end

  ##--------------------------------------------------
  def putNameSpaceEntry(key, prefix, uri, table = NameSpaceTable)
    table[key] = [prefix, uri] ;
  end

  ##--------------------------------------------------
  def getNameSpaceEntry(key, errorP = true, table = NameSpaceTable)
    entry = table[key] ;
    raise("Unknown namespace key:" + key.to_s) if(entry.nil? && errorP)
    entry ; 
  end
  
  ##--------------------------------------------------
  def getNameSpacePrefix(key, errorP = true, table = NameSpaceTable)
    r = getNameSpaceEntry(key, errorP, table) ;
    if(r.nil?)
      return r ;
    else
      return r[0] ;
    end
  end

  ##--------------------------------------------------
  def getNameSpaceUri(key, errorP = true, table = NameSpaceTable)
    r = getNameSpaceEntry(key, errorP, table) ;
    if(r.nil?)
      return r ;
    else
      return r[1] ;
    end
  end
  
  ##----------------------------------------------------------------------
  ## general XML utility

  ##--------------------------------------------------
  def newElement(name,text=nil, table = NameSpaceTable)  
    # name = fullname | [ namespace, localname, [attrName, attrValue]* ]

    attrList = nil ;

    ## construct tage name
    if(name.is_a?(Array))
      prefixKey = name[0] ;
      localname = name[1] ;
      prefix = getNameSpacePrefix(prefixKey, nil, table) ;
      prefix = prefixKey if prefix.nil? ;
      attrList = name[2..-1] ;
      if(prefix)
        name = prefix.to_s + ":" + localname.to_s ;
      else
        name = localname.to_s ;
      end
    end
    
    ## genenete element
    elm = XML::Element::new(name.to_s) ;

    ## add attributes
    if(attrList)
      attrList.each{|attr|  
        if(attr.is_a?(Array))
          elm.add_attribute(attr[0].to_s, attr[1].to_s) ;
        elsif(attr.is_a?(Hash))
          attr.each{|key, value|
            elm.add_attribute(key.to_s, value.to_s) ;
          }
        elsif(attr.nil?)
          # do nothing ;
        else
          raise "unknown attribute form" ;
        end
      }
    end

    ## add text body
    if(text) 
      text = text.dup if(text.frozen?()) ;
      elm.add(XML::Text::new(text.to_s)) 
    end

    elm ;
  end

  ##--------------------------------------------------
  def addNameSpace(elm, name, uri = nil)
    if(uri.nil?)  # suppose name is a key in NameSpaceTable
      nsEntry = getNameSpaceEntry(name) ;
      elm.add_namespace(nsEntry[0],nsEntry[1]) ;
    elsif(name.nil?) # suppose default namespace
      uri = getNameSpaceUri(uri) if(uri.is_a?(Symbol)) ;
      elm.add_namespace(uri) ;
    else # suppsoe name is a prefix, uri is a full name.
      uri = getNameSpaceUri(uri) if(uri.is_a?(Symbol)) ;
      elm.add_namespace(name, uri) ;
    end
    elm ;
  end

  ##--------------------------------------------------
  def addNameSpaceAsDefault(elm, key)
    addNameSpace(elm, nil, getNameSpaceUri(key)) ;
  end

  ##--------------------------------------------------
  def addNameSpaceList(elm, nsList) 
    nsList.each{|namespace|
      if(namespace.is_a?(Array))
        (prefix, uri) = namespace ;
        addNameSpace(elm, prefix, uri) ;
      else
        addNameSpace(elm,namespace) ;
      end
    }
    elm ;
  end

  ##----------------------------------------------------------------------
  ## Array to XML utility
  ##   <Form> ::= <Text> | <XML> | <Struct>
  ##   <Text> ::= any_string_or_atoms
  ##   <XML>  ::= any_xml_element | any_xml_text
  ##   <Struct> ::= '[' <Tag> ',' <Form>* ']'
  ##   <Tag> ::= <TagName> | '[' <NameSpace> ',' <LocalName> ',' <Attribute>* ']'
  ##   <TagName> ::= any_string_or_atoms
  ##   <NameSpace> ::= any_string_or_atoms
  ##   <LocalName> ::= any_string_or_atoms
  ##   <Attribute> ::= '[' <AttrName> <AttrValue> ']' | <RubyHash>
  ##   <AttrName> ::= any_string_or_atoms
  ##   <AttrValue> ::= any_string_or_atoms

  def to_Xml(form, nsTable = NameSpaceTable)
    if    (form.is_a?(XML::Element) || form.is_a?(XML::Text))
      return form ;
    elsif (form.is_a?(Array))
      elm = nil ;
      form.each{|child|
        if(elm.nil?)
          elm = newElement(child,nil,nsTable) ;
        else
          elm.add(to_Xml(child, nsTable))
        end
      }
      return elm ;
    else
      return XML::Text::new(form.to_s) ;
    end
  end

  ##----------------------------------------------------------------------
  ## Array to XML Schema
  ##  <Text> ::= :integer | :float | :string | :geo | :any
  ##  <AttrValue> ::= :integer | :float | :string

  XmlSchemaTypeTable = {
    :integer => 'integer',
    :float   => 'float',
    :string  => 'string',
    :geo     => 'geometryPropertyType',
    :any     => 'AnyXML',
    nil => nil} ;

  ##--------------------------------------------------
  def to_XmlSchema(form, uri, nsTable = NameSpaceTable)
    formstr = form.inspect.gsub('"',"") ;

    schema = to_Xml([[:xsd, 'schema'],
                      [[:xsd, 'annotation'],
                        [[:xsd, 'appinfo'],
                          [[:daruma, 'daruma'],
                            [[:daruma, 'originalForm'], formstr],
                            [[:daruma, 'uri'], uri]]]]]) ;

    usedNs = [:xsd, :daruma] ;

    to_XmlSchemaBodyTop(form, schema, nsTable, usedNs) ;

    usedNs.uniq! ;
    usedNs.each{|ns|
      addNameSpace(schema, ns) ;
    }
    
    schema ;
  end

  ##--------------------------------------------------
  def to_XmlSchemaBodyTop(form, schema, nsTable, usedNs)
    (elementDef,hasSubDefP, typename) = 
      to_XmlSchemaBodyElement(form, nsTable, usedNs) ;

    schema.add(elementDef) ;
    
    if(hasSubDefP) 
      to_XmlSchemaBodyTypeDef(form, typename, schema, nsTable, usedNs) ;
    end

    schema ;
  end

  ##--------------------------------------------------
  def to_XmlSchemaBodyElement(form, nsTable, usedNs)
    tag = form[0] ;

    if(tag.is_a?(Array) && tag[0])
      usedNs.push(tag[0]) ;
    end

    elm = newElement(tag, nil, nsTable) ;
    fullname = elm.fully_expanded_name() ;

    type = form[1] ;

    if(type.is_a?(Symbol))
      xsdType = XmlSchemaTypeTable[type] ;
      if(xsdType.nil?)
        raise "unknown XML Schmea simple type key: " + type.inspect ;
      end
      typename = xsdType ;
      hasSubDefP = false ;
    else
      typename = fullname + "Type" ;
      hasSubDefP = true ;
    end
    
    elementDef = to_Xml([[:xsd, 'element', 
                            ['name', fullname],
                            ['type', typename]]]) ;

    return elementDef, hasSubDefP, typename ;
  end

  ##--------------------------------------------------
  def to_XmlSchemaBodyTypeDef(form, typename, schema, nsTable, usedNs)
    nElement = form.length ;
    elementList = [[:xsd, 'sequence']] ;
    subDefList = [] ;

    (1...nElement).each{|i|
      child = form[i] ;
      (elementDef, hasSubDefP, subTypename) = 
        to_XmlSchemaBodyElement(child, nsTable, usedNs) ;
      elementList.push(elementDef) ;
      subDefList.push([child, subTypename]) if(hasSubDefP) ;
    }

    attrs = form[0] ;
    nAttr = attrs.length ;
    contentDef = [[:xsd, 'complexContent'], elementList] ;
    
    (2...nAttr).each{|i|
      (name, type) = attrs[i] ;
      contentDef.push([[:xsd, 'attribute', 
                          ['name', name],
                          ['type', XmlSchemaTypeTable[type]]]]) ;
    }
    
    typeDef = to_Xml([[:xsd, 'complexType', ['name',typename]], contentDef]) ;

    schema.add(typeDef) ;

    subDefList.each{|child|
      (subForm, subTypename) = child ;
      to_XmlSchemaBodyTypeDef(subForm, subTypename, schema, nsTable, usedNs) ;
    }

    schema ;
  end

  ##----------------------------------------------------------------------
  ## header and tailer strings

  ##--------------------------------------------------
  ## genHeaderTailerString(form)
  ##  <Text> ::= <SpecialTag> | <Text>
  ##  <SpecialTag> ::= :body

  MagicTagForBody = '@@@HereIsBody@@@' ;
  MagicTagForCR = '@@@HereIsCR@@@' ;
  DefaultSpecialBodyTag = :body ;

  def genHeaderTailerString(form, nsList = [], specialBodyTag = DefaultSpecialBodyTag)
    form = substTagToText(form, specialBodyTag, MagicTagForBody) ;

    xml = to_Xml(form) ;
    addNameSpaceList(xml, nsList) ;

    return splitHeaderTailerString(xml, MagicTagForBody) ;
  end

  def splitHeaderTailerAt(node, point)
    point.add(XML::Text::new(MagicTagForBody)) ;

    return splitHeaderTailerString(node, MagicTagForBody) ;
  end

  def splitHeaderTailerString(xml, splitTag)
    str = '' ;
    ppp(xml,str) ;

    str.gsub!("\n",MagicTagForCR) ;

    str =~ /^(.*)#{splitTag}(.*)$/ ;
    header = $1 ;
    tailer = $2 ;

    header.gsub!(MagicTagForCR, "\n") ;
    tailer.gsub!(MagicTagForCR, "\n") ;

    return header,tailer ;
  end

  ##--------------------------------------------------
  def substTagToText(form, tag, text)
    if(form == tag)
      return text ;
    elsif(form.is_a?(Array))
      (1...form.length).each{|i|
        form[i] = substTagToText(form[i],tag,text) ;
      }
      return form ;
    else
      return form ;
    end
  end

  ##--------------------------------------------------
  def genCollectionHeaderTailer(nsList = [], soapP = false)
    genHeaderTailerString(['collection', :body],nsList.push(:gml)) ;
  end

  ##--------------------------------------------------
  def genUniversalName(namespace, localname)
    return ("{%s}%s" % [namespace,localname]) ;
  end
    
  ##----------------------------------------------------------------------
  def ppp(xml, strm = $stdout)
    if(REXML::Version <= "3.1.4") then
      xml.write(strm,0) ;
    else
      indent = 2 ;
      REXML::Formatters::Pretty.new(indent,false).write(xml, strm) ;
    end
    strm << "\n" ;
  end

end

class << ItkXml
  extend ItkXml ;
  include ItkXml ;
end

##======================================================================
##======================================================================
##======================================================================
if ($0 == __FILE__)

  require 'pp.rb' ;

  ##--------------------------------------------------
  def test1 ()
    data = [:foo, [:bar, 1], ['baz', "hoge"]] ;
    pp(data) ;
    xml = ItkXml.to_Xml(data) ;
    ItkXml::ppp(xml) ;
  end

  ##--------------------------------------------------
  ##--------------------------------------------------
  ##--------------------------------------------------
  # test main
  
  test1() ;
  
end

