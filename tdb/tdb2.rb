## -*- Mode: ruby -*-
##Header:
##Title: Text Database Parser by Ruby
##Author: Itsuki Noda
##Type: subroutine
##Date: 2001/04/14
##EndHeader:

##ModifyHistory:
# 1995/04/18: Add '^_\s*Slot: Value' format
# 1995/04/18: Add @Entry (order of slot)
# 1995/04/21: Add getTdbEntry
# 1995/08/09: Add '：' (in EUC)
# 2001/04/14: converted to ruby
##EndModifyHistory:

##Note:
# TextDB Format
#  ^BeginEntry:(_ID_)\n --- \nEndEntry:\n     One Entry
#  ^\[:(_ID_)\n --- \n\]:\n     One Entry
#  ^Slot: Value                               Slot/Value Pair
#  ^_\s*Slot: Value                           Slot/Value Pair 
#  % --- $                                    Comment ( skip )
#
##EndNote:

##Usage:
#  [briefed]
#  db = scanDB(stream)		# scan whole db
#  entry = db[id]		# get one entry by id
#  value = entry[slot]		# get a slot value
#
#  [detailed]
#  entry = scanEntry (stream)	# scan one db
#  
#  entry = db.get(id)		# get entry by id
#  value = entry.value[slot]	# get slot-value by slot
#  db.put(id,entry)		# put entry to id
#
##EndUsage:

require "kconv" ;

$useEUC = false ;

module Tdb

  extend self,self ;

  ##======================================================================
  ## constant
  ##----------------------------------------------------------------------

  if($AllowEUCJapan || $AllowUTF8) then
    $SLOTSEPMARK = ":：" ;
  else
    $SLOTSEPMARK = ":" ;
  end

  IDKEY = '_ID_' ;
  TOPLEVEL_ID = '_TOP_' ;
  NOTESLOT = '_NOTE_' ;

  ##======================================================================
  ## class TdbEntry
  ##----------------------------------------------------------------------

  class Entry

    ##--------------------------------------------------
    ## line token type

    TknNull	= 'tkn_null'  ;	# null line
    TknEntry	= 'tkn_entry' ; # entry
    TknEnd      = 'tkn_end'   ; # end entry
    TknSlot     = 'tkn_slot'  ; # slot value pair
    TknCont	= 'tkn_cont'  ; # continuous line
    TknEof	= 'tkn_eof'   ; # end of file

    ##--------------------------------------------------
    ## attributes

    attr :list,		true ;  # should be array.  exhaustive list of slots
    attr :value,	true ; 	# should be hash
    attr :slot,		true ;	# should be array
    attr :children,	true ;  # embedded entry
    attr :preslot,	true ;  # previous slot.  used for continuous lines

    ##--------------------------------------------------
    ## init

    def initialize ()
      @list = Array::new() ;
      @value = Hash::new() ;
      @slot = Array::new() ;
      @children = Array::new() ;
    end

    ##--------------------------------------------------
    ## output

    def to_s
#      sprintf("#Tdb::Entry[%s:%s]",value[IDKEY],value) ;
      sprintf("#Tdb::Entry[%s]",value[IDKEY]) ;
    end

    ##--------------------------------------------------
    ## get  ; get entry (or slot-value) by id

    def get(id)
      return @value[id] ;
    end

    def [](id)
      return get(id)
    end

    ##--------------------------------------------------
    ## getNakedValue  ; get value and remove spaces of head/tail.

    def getNakedValue(id)
      value = get(id) ;
      if(!value.nil?)
        value = value.gsub(/^\s+/,'').gsub(/\s+$/,'') ;
      end
      return value ;
    end

    ##--------------------------------------------------
    ## putSlotValue
    ##  

    def putSlotValue(s,v)
      #@allvalue.push(v) ;
      @list.push(v) ;
      @slot.push(s) ;
      @value[s] = v ;
      @preslot = s ;
    end

    def putEntry(id,entry)
      putSlotValue(id,entry) ;
    end

    ##--------------------------------------------------
    ## get a list of entry/slot (return an array)

    def slotList()
      return slot
    end

    def entryList()
      return slot
    end

    ##============================================================
    ## scan

    ##--------------------------------------------------
    ## scan entry body (start inside of entry)
    ##  

    def scanEntryBody (strm) 
      while(line = strm.gets()) do
	line = Kconv::kconv(line,($useEUC ? Kconv::EUC : Kconv::UTF8)) ;
	if(scanLine(strm,line) == TknEnd) then 
	  return TknEnd ;		# return by end entry mark
	end
      end
      return TknEof ;		# return by eof
    end

    ##--------------------------------------------------
    ## scan one entry (start outside of entry)
    ##  

    def scanOneEntry (strm)
      while(line = strm.gets()) do
	line = Kconv::kconv(line,($useEUC ? Kconv::EUC : Kconv::UTF8)) ;
	token = scanLine(strm,line) ;
	if(token == TknEntry)
	  return true ;
	end
      end
      return false ;
    end

    ##--------------------------------------------------
    ## scan line
    ##  return TRUE if it is not the end of entry

    def scanLine(strm,line) 
      line.chop() ;

      if(line =~ /^\%/) then	# skip comment line
	return TknNull ;
      end

      line.sub!(/\%.*$/,'') ;	# trim comment part


#      if (line =~ /^(BeginEntry|\[)[$SLOTSEPMARK][\s]*([^\s]*)[\s]*$/o) then
      if (line =~ /^(BeginEntry|\[)[\:][\s]*([^\s]*)[\s]*$/o) then
					# begin entry
	id = $2 ;
	child = Entry::scanNewEntry(strm,id) ;
	putSlotValue(id,child) ;
	@preslot = NOTESLOT ;
	@children.push(child) ;
	
	return TknEntry ;

#      elsif (line =~ /(EndEntry|\])[$SLOTSEPMARK]/o) then 
      elsif (line =~ /(EndEntry|\])[\:]/o) then 
					# end entry
	return TknEnd ;

#      elsif (line =~ /^(|_\s*)([^$SLOTSEPMARK\s]+)[$SLOTSEPMARK](.*)$/o) then
      elsif (line =~ /^(|_\s*)([^\:\s]+)[\:](.*)$/o) then
					# slot-value line
	s = $2 ;
	v = $3 ;
	putSlotValue($2,$3) ;
	return TknSlot ;

      else
					# continuous value line
	if(@value[@preslot]) then
	  @value[@preslot] << "\n" + line ;
	else
	  @value[@preslot] = "\n" + line ;
	end
	return TknCont ;

      end
    end

    ##--------------------------------------------------
    ## scan DB
    ##  
    
    def scanDB(strm)
      if(scanEntryBody(strm) == Entry::TknEnd) then
	$strerr << "Warning: toplevel ends by end entry mark\n" ;
      end
    end

  end

  ##======================================================================
  ## Entry::scanNewEntry
  ##  

#  def Entry::scanNewEntry(strm,id=TOPLEVEL_ID) 
  def Entry::scanNewEntry(strm,id)
    entry = Entry::new ;

    entry.putSlotValue(IDKEY,id) ;
    entry.preslot = NOTESLOT ;

    entry.scanEntryBody(strm) ;

### check is move to Entry's instance method scanDB()
#    if(entry.scanEntryBody(strm) == Entry::TknEnd && id == TOPLEVEL_ID) then
#      $strerr << "Warning: toplevel ends by end entry mark\n" ;
#    end

    return entry ;
  end

  ##======================================================================
  ## scan DB
  ##  

  def scanDB(strm)
#    return Entry::scanNewEntry(strm) ;
    db = newDB() ;
    db.scanDB(strm) ;
    return db ;
  end

  ##======================================================================
  ## new DB
  ##  

  def Entry::newDB()
    db = Entry::new ;

    db.putSlotValue(IDKEY,TOPLEVEL_ID) ;
    db.preslot = NOTESLOT ;
    
    return db ;
  end

  def newDB()
    return Entry::newDB() ;
  end

  def Tdb.newDB()
    return Entry::newDB() ;
  end

  ##======================================================================
  ## scan one entry
  ##  

  def scanEntry(strm)
    tmpdb = Entry::new ;
    tmpdb.scanOneEntry(strm) ;
    return tmpdb.children.pop() ;
  end

end





