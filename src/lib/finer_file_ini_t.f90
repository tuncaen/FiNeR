!< INI file class definition.
module finer_file_ini_t
!-----------------------------------------------------------------------------------------------------------------------------------
!< INI file class definition.
!-----------------------------------------------------------------------------------------------------------------------------------
use finer_backend
use finer_option_t, only : option
use finer_section_t, only : section
use penf
use stringifor
use, intrinsic :: iso_fortran_env, only : stdout => output_unit
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public :: file_ini
public :: file_ini_autotest
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type :: file_ini
  !< INI file class.
  character(len=:), allocatable       :: filename              !< File name
  integer(I4P)                        :: Ns = 0                !< Number of sections.
  character(1)                        :: opt_sep = def_opt_sep !< Separator character of option name/value.
  type(section), allocatable, private :: sections(:)           !< Sections.
  contains
    procedure :: free                                                 !< Free dynamic memory destroyng file data.
    generic ::   free_options => free_options_all,        &           !< Free all options.
                                 free_options_of_section, &           !< Free all options of a section.
                                 free_option_of_section_file_ini      !< Free an option of a section.
    procedure :: load                                                 !< Load file data.
    procedure :: has_option   => has_option_file_ini                  !< Inquire the presence of an option.
    procedure :: has_section  => has_section_file_ini                 !< Inquire the presence of a section.
    procedure :: section      => section_file_ini                     !< Get section name once provided an index.
    generic ::   index        => index_section_file_ini, &            !< Return the index of a section.
                                 index_option_file_ini                !< Return the index of an option.
    procedure :: count_values => count_values_option_section_file_ini !< Count option value(s).
    generic ::   add          => add_section_file_ini,       &        !< Add a section.
                                 add_option_section_file_ini,&        !< Add an option to a section (scalar).
                                 add_a_option_section_file_ini        !< Add an option to a section (array).
    generic ::   get          => get_option_section_file_ini, &       !< Get option value (scalar).
                                 get_a_option_section_file_ini        !< Get option value (array).
    generic ::   del          => free_option_of_section_file_ini, &   !< Remove (freeing) an option of a section.
                                 free_section_file_ini                !< Remove (freeing) a section.
    procedure :: items        => items_file_ini                       !< Get list of couples option name/value.
    generic ::   loop         => loop_options_section_file_ini, &     !< Loop over options of a section.
                                 loop_options_file_ini                !< Loop over all options.
    procedure :: print        => print_file_ini                       !< Pretty printing data.
    procedure :: save         => save_file_ini                        !< Save data.
    ! operators overloading
    generic:: assignment(=) => assign_file_ini !< Procedure for section assignment overloading.
    ! private procedures
    procedure, private              :: parse                           !< Parse file data.
    procedure, private              :: free_options_all                !< Free all options of all sections.
    procedure, private              :: free_options_of_section         !< Free all options of a section.
    procedure, private              :: free_option_of_section_file_ini !< Free an option of a section.
    procedure, private              :: free_section_file_ini           !< Free a section.
    procedure, private              :: index_section_file_ini          !< Return the index of a section.
    procedure, private              :: index_option_file_ini           !< Return the index of an option.
    procedure, private              :: add_section_file_ini            !< Add a section.
    procedure, private              :: add_option_section_file_ini     !< Add an option to a section (scalar).
    procedure, private              :: add_a_option_section_file_ini   !< Add an option to a section (scalar).
    procedure, private              :: get_option_section_file_ini     !< Get option value (scalar).
    procedure, private              :: get_a_option_section_file_ini   !< Get option value (array).
    procedure, private              :: loop_options_section_file_ini   !< Loop over options of a section.
    procedure, private              :: loop_options_file_ini           !< Loop over all options.
    procedure, private, pass(lhs) :: assign_file_ini                 !< Assignment overloading.
endtype file_ini
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  elemental subroutine free(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(inout) :: self !< File data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%filename)) deallocate(self%filename)
  if (allocated(self%sections)) then
    call self%sections%free
    deallocate(self%sections)
  endif
  self%Ns = 0
  self%opt_sep = def_opt_sep
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  elemental subroutine free_options_all(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free all options of all sections.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(inout):: self !< File data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%sections)) call self%sections%free_options
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_options_all

  elemental subroutine free_options_of_section(self, section_name)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free all options of a section.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(inout) :: self         !< File data.
  character(*),    intent(in)    :: section_name !< Section name.
  integer(I4P)                   :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%sections)) then
    do s=1, size(self%sections, dim=1)
      if (self%sections(s)%sname == section_name) then
        call self%sections(s)%free_options
        exit
      endif
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_options_of_section

  elemental subroutine free_option_of_section_file_ini(self, section_name, option_name)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free all options of a section.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(inout) :: self         !< File data.
  character(*),    intent(in)    :: section_name !< Section name.
  character(*),    intent(in)    :: option_name  !< Option  name.
  integer(I4P)                   :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  s = self%index(section_name=section_name)
  if (s>0) call self%sections(s)%free_option(option_name=option_name)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_option_of_section_file_ini

  elemental subroutine free_section_file_ini(self, section_name)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free all options of a section.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(inout) :: self         !< File data.
  character(*),    intent(in)    :: section_name !< Section name.
  type(section), allocatable     :: sections(:)  !< Temporary sections array.
  integer(I4P)                   :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  s = self%index(section_name=section_name)
  if (s>0) then
    allocate(sections(1:size(self%sections, dim=1)-1))
    if (s==1) then
      sections = self%sections(2:)
    elseif (s==size(self%sections, dim=1)) then
      sections = self%sections(:s-1)
    else
      sections(:s-1) = self%sections(:s-1)
      sections(s:  ) = self%sections(s+1:)
    endif
    call move_alloc(sections, self%sections)
    self%Ns = self%Ns - 1
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_section_file_ini

  subroutine load(self, separator, filename, source, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get file data from a file or a source string.
  !<
  !<### Usage
  !<
  !<##### Loading from a file
  !<```bash
  !<type(file_ini):: fini
  !<call fini%load(filename='path_to_my_file.ini')
  !<```
  !<
  !<##### Loading from a source string
  !<```bash
  !<type(file_ini):: fini
  !<call fini%load(source='[section-1] option-1=one [section-2] option-2=due')
  !<```
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(inout) :: self      !< File data.
  character(1), optional, intent(in)    :: separator !< Separator of options name/value.
  character(*), optional, intent(in)    :: filename  !< File name.
  character(*), optional, intent(in)    :: source    !< File source.
  integer(I4P), optional, intent(out)   :: error     !< Error code.
  integer(I4P)                          :: errd      !< Error code.
  character(len=:), allocatable         :: sourced   !< Dummy source string.
  type(string)                          :: source_   !< Dummy source string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  errd = err_source_missing
  if (present(separator)) self%opt_sep = separator
  if (present(filename)) then
    self%filename = trim(adjustl(filename))
    ! to remove after StringiFor adoption
    call source_%read_file(file=self%filename)
    sourced = source_%chars()
    ! call read_file_as_stream(filename=self%filename, fast_read=.true., stream=sourced)
    ! to remove after StringiFor adoption
    call self%parse(source=sourced, error=errd)
  elseif (present(source)) then
    call self%parse(source=source, error=errd)
  elseif (allocated(self%filename)) then
    ! to remove after StringiFor adoption
    call source_%read_file(file=self%filename)
    sourced = source_%chars()
    ! call read_file_as_stream(filename=self%filename, fast_read=.true., stream=sourced)
    call self%parse(source=sourced, error=errd)
  endif
  if (present(error)) error = errd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine load

  subroutine parse(self, source, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse file either from the self source data or from a source string.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(inout)   :: self      !< File data.
  character(*),           intent(in)      :: source    !< String source.
  integer(I4P), optional, intent(out)     :: error     !< Error code.
  integer(I4P)                            :: errd      !< Error code.
  type(string), allocatable               :: tokens(:) !< Options strings tokenized.
  type(string)                            :: dummy_str !< Dummy string.
  character(len=len(source)), allocatable :: toks(:)   !< Dummies tokens.
  character(len(source))                  :: dummy     !< Dummy string for parsing sections.
  integer(I4P)                            :: Ns        !< Counter.
  integer(I4P)                            :: s         !< Counter.
  integer(I4P)                            :: ss        !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  errd = err_source_missing
  ! to remove after StringiFor adoption
  dummy_str = source
  call dummy_str%split(tokens=tokens, sep=new_line('a'))
  allocate(toks(1:size(tokens, dim=1)))
  do s =1, size(tokens, dim=1)
    toks(s) = tokens(s)%chars()
  enddo
  ! call tokenize(strin=source, delimiter=new_line('A'), toks=toks)
  ! to remove after StringiFor adoption
  Ns = 0
  s = 0
  do while (s+1<=size(toks, dim=1))
    s = s + 1
    if (scan(adjustl(toks(s)), comments) == 1) cycle
    if (index(trim(adjustl(toks(s))), "[") == 1) then
      Ns = Ns + 1
      dummy = trim(adjustl(toks(s)))//new_line('A')
      ss = s
      do while (ss+1<=size(toks, dim=1))
        ss = ss + 1
        if (index(trim(adjustl(toks(ss))), "[") == 1) then
          ! new section... go back
          exit
        else
          ! continuation of current section
          dummy = trim(adjustl(dummy))//new_line('A')//trim(adjustl(toks(ss)))
          toks(ss) = comments ! forcing skip this in the following scan
        endif
      enddo
      toks(s) = trim(adjustl(dummy))
    endif
  enddo
  if (Ns>0) then
    if (allocated(self%sections)) deallocate(self%sections) ; allocate(self%sections(1:Ns))
    s = 0
    ss = 0
    do while (s+1<=size(toks, dim=1))
      s = s + 1
      if (scan(adjustl(toks(s)), comments) == 1) cycle
      if (index(trim(adjustl(toks(s))), "[") == 1) then
        ss = ss + 1
        call self%sections(ss)%parse(sep=self%opt_sep, source=toks(s), error=errd)
      endif
    enddo
  endif
  self%Ns = size(self%sections, dim=1)
  if (present(error)) error = errd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse

  function has_option_file_ini(self, section_name, option_name) result(pres)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Inquire the presence of (at least one) option with the name passed.
  !<
  !< Optionall, the first matching section name is returned.
  !<
  !< @note All sections are searched and the first occurence is returned.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(in)    :: self         !< File data.
  character(*), optional, intent(inout) :: section_name !< Section name.
  character(*),           intent(in)    :: option_name  !< Option name.
  logical                               :: pres         !< Inquiring flag.
  integer(I4P)                          :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  pres = .false.
  if (allocated(self%sections)) then
    do s=1, size(self%sections, dim=1)
      pres = (self%sections(s)%index(option_name=option_name)>0)
      if (pres) then
        if (present(section_name)) section_name = self%sections(s)%sname
        exit
      endif
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction has_option_file_ini

  elemental function has_section_file_ini(self, section_name) result(pres)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Inquire the presence of (at least one) section with the name passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(in) :: self         !< File data.
  character(*),    intent(in) :: section_name !< Section name.
  logical                     :: pres         !< Inquiring flag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  pres = (self%index(section_name=section_name)>0)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction has_section_file_ini

  elemental function index_section_file_ini(self, back, section_name) result(ind)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Return the index of the section matching the name passed.
  !<
  !< @note The matching index returned is the first found if *back* is not passed or if *back=.false.*. On the contrary the last
  !< found is returned if *back=.true.*.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),   intent(IN) :: self         !< File data.
  logical, optional, intent(IN) :: back         !< If back appears with the value true, the last matching index is returned.
  character(*),      intent(IN) :: section_name !< Section name.
  integer(I4P)                  :: ind          !< Index of searched section.
  logical                       :: backd        !< Dummy back flag.
  integer(I4P)                  :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ind = 0
  if (allocated(self%sections)) then
    backd = .false. ; if (present(back)) backd = back
    if (backd) then
      do s=size(self%sections, dim=1), 1,-1
        if (self%sections(s)%sname == trim(adjustl(section_name))) then
          ind = s
          exit
        endif
      enddo
    else
      do s=1, size(self%sections, dim=1)
        if (self%sections(s)%sname == trim(adjustl(section_name))) then
          ind = s
          exit
        endif
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction index_section_file_ini

  elemental function index_option_file_ini(self, back, section_name, option_name) result(ind)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Return the index of the option (inside a  section) matching the name(s) passed.
  !<
  !< @note The matching index returned is the first found if *back* is not passed or if *back=.false.*. On the contrary the last
  !< found is returned if *back=.true.*.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),   intent(in) :: self         !< File data.
  logical, optional, intent(in) :: back         !< If back appears with the value true, the last matching index is returned.
  character(*),      intent(in) :: option_name  !< Option  name.
  character(*),      intent(in) :: section_name !< Section name.
  integer(I4P)                  :: ind          !< Index of searched section.
  logical                       :: backd        !< Dummy back flag.
  integer(I4P)                  :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ind = 0
  if (allocated(self%sections)) then
    backd = .false. ; if (present(back)) backd = back
    s = self%index(section_name=section_name, back=backd)
    if (s>0) then
      ind = self%sections(s)%index(option_name=option_name, back=backd)
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction index_option_file_ini

  pure function section_file_ini(self, section_index) result(sname)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get section name once an index (valid) is provided.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(in)   :: self          !< File data.
  integer(I4P),    intent(in)   :: section_index !< Section index.
  character(len=:), allocatable :: sname         !< Section name.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%sections)) then
    if ((section_index >= lbound(self%sections, dim=1)).and.(section_index <= ubound(self%sections, dim=1))) then
      if (allocated(self%sections(section_index)%sname)) sname = self%sections(section_index)%sname
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction section_file_ini

  elemental function count_values_option_section_file_ini(self, delimiter, section_name, option_name) result(Nv)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get the number of values of option into section data.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(in) :: self         !< File data.
  character(*), optional, intent(in) :: delimiter    !< Delimiter used for separating values.
  character(*),           intent(in) :: section_name !< Section name.
  character(*),           intent(in) :: option_name  !< Option name.
  integer(I4P)                       :: Nv           !< Number of values.
  character(len=:), allocatable      :: dlm          !< Dummy string for delimiter handling.
  integer(I4P)                       :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%sections)) then
    dlm = ' ' ; if (present(delimiter)) dlm = delimiter
    do s=1, size(self%sections, dim=1)
      if (self%sections(s)%sname == trim(adjustl(section_name))) then
        Nv = self%sections(s)%count_values(delimiter=dlm, option_name=option_name)
        exit
      endif
    enddo
  endif
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction count_values_option_section_file_ini

  subroutine add_section_file_ini(self, error, section_name)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add a section.
  !<
  !< If the section already exists, it is left unchanged.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(inout) :: self         !< File data.
  integer(I4P), optional, intent(out)   :: error        !< Error code.
  character(*),           intent(in)    :: section_name !< Section name.
  type(section), allocatable            :: sections(:)  !< Temporary sections array.
  integer(I4P)                          :: errd         !< Error code.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  errd = err_section
  if (allocated(self%sections)) then
    if (self%index(section_name=section_name)==0) then
      ! section not present
      allocate(sections(1:size(self%sections, dim=1)+1))
      sections(1:size(self%sections, dim=1)) = self%sections
      sections(size(self%sections, dim=1)+1) = section(sname=trim(adjustl(section_name)))
      call move_alloc(sections, self%sections)
      self%Ns = self%Ns + 1
    endif
  else
    allocate(self%sections(1:1))
    self%sections(1)%sname = section_name
    self%Ns = self%Ns + 1
  endif
  if (self%index(section_name=section_name)>0) errd = 0
  if (present(error)) error = errd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_section_file_ini

  subroutine add_option_section_file_ini(self, error, section_name, option_name, val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add an option (with scalar value).
  !<
  !< If the option already exists, its value is updated.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(inout) :: self         !< File data.
  integer(I4P), optional, intent(out)   :: error        !< Error code.
  character(*),           intent(in)    :: section_name !< Section name.
  character(*),           intent(in)    :: option_name  !< Option name.
  class(*),               intent(in)    :: val          !< Option value.
  integer(I4P)                          :: errd         !< Error code.
  integer(I4P)                          :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  errd = err_section_options
  call self%add(section_name=section_name, error=errd)
  if (errd==0) then
    do s=1, size(self%sections, dim=1)
      if (self%sections(s)%sname == section_name) then
        call self%sections(s)%add(error=errd, option_name=option_name, val=val)
        exit
      endif
    enddo
  endif
  if (present(error)) error = errd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_option_section_file_ini

  subroutine add_a_option_section_file_ini(self, error, section_name, option_name, val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add an option (with array value).
  !<
  !< If the option already exists, its value is updated.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(inout) :: self         !< File data.
  integer(I4P), optional, intent(out)   :: error        !< Error code.
  character(*),           intent(in)    :: section_name !< Section name.
  character(*),           intent(in)    :: option_name  !< Option name.
  class(*),               intent(in)    :: val(1:)      !< Option value.
  integer(I4P)                          :: errd         !< Error code.
  integer(I4P)                          :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  errd = err_section_options
  call self%add(section_name=section_name, error=errd)
  if (errd==0) then
    do s=1, size(self%sections, dim=1)
      if (self%sections(s)%sname == section_name) then
        call self%sections(s)%add(error=errd, option_name=option_name, val=val)
        exit
      endif
    enddo
  endif
  if (present(error)) error = errd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_a_option_section_file_ini

  subroutine get_option_section_file_ini(self, error, section_name, option_name, val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get option value (scalar).
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(in)    :: self         !< File data.
  integer(I4P), optional, intent(out)   :: error        !< Error code.
  character(*),           intent(in)    :: section_name !< Section name.
  character(*),           intent(in)    :: option_name  !< Option name.
  class(*),               intent(inout) :: val          !< Value.
  integer(I4P)                          :: errd         !< Error code.
  integer(I4P)                          :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%sections)) then
    do s=1, size(self%sections, dim=1)
      if (self%sections(s)%sname == trim(adjustl(section_name))) then
        call self%sections(s)%get(error=errd, option_name=option_name, val=val)
        if (present(error)) error = errd
        exit
      endif
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_option_section_file_ini

  subroutine get_a_option_section_file_ini(self, delimiter, error, section_name, option_name, val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get option value (array)
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(in)    :: self         !< File data.
  character(*), optional, intent(in)    :: delimiter    !< Delimiter used for separating values.
  integer(I4P), optional, intent(out)   :: error        !< Error code.
  character(*),           intent(in)    :: section_name !< Section name.
  character(*),           intent(in)    :: option_name  !< Option name.
  class(*),               intent(inout) :: val(1:)      !< Value.
  character(len=:), allocatable         :: dlm          !< Dummy string for delimiter handling.
  integer(I4P)                          :: errd         !< Error code.
  integer(I4P)                          :: s            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  dlm = ' ' ; if (present(delimiter)) dlm = delimiter
  if (allocated(self%sections)) then
    do s=1, size(self%sections, dim=1)
      if (self%sections(s)%sname == trim(adjustl(section_name))) then
        call self%sections(s)%get(delimiter=dlm, error=errd, option_name=option_name, val=val)
        if (present(error)) error = errd
        exit
      endif
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_a_option_section_file_ini

  pure function items_file_ini(self) result(items)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get list of couples option name/value.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(in)   :: self       !< File data.
  character(len=:), allocatable :: items(:,:) !< Items, list of couples option name/value for all options [1:No,1:2].
  integer(I4P)                  :: mx_chars   !< Maximum number of chars into name/value within all options.
  integer(I4P)                  :: o          !< Counter.
  integer(I4P)                  :: s          !< Counter.
  integer(I4P)                  :: No         !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mx_chars = MinI4P
  if (allocated(self%sections)) then
    No = 0
    do s=1, size(self%sections, dim=1)
      if (allocated(self%sections(s)%options)) then
        do o=1, size(self%sections(s)%options, dim=1)
          No = No + 1
          mx_chars = max(mx_chars, len(self%sections(s)%options(o)%oname), len(self%sections(s)%options(o)%ovals))
        enddo
      endif
    enddo
    if ((mx_chars > 0).and.(No > 0)) then
      allocate(character(mx_chars):: items(1:No, 1:2))
      No = 0
      do s=1, size(self%sections, dim=1)
        if (allocated(self%sections(s)%options)) then
          do o=1, size(self%sections(s)%options, dim=1)
            No = No + 1
            items(No, 1) = self%sections(s)%options(o)%oname
            items(No, 2) = self%sections(s)%options(o)%ovals
          enddo
        endif
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction items_file_ini

  function loop_options_section_file_ini(self, section_name, option_pairs) result(again)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Loop returning option name/value defined into section.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),               intent(in)  :: self            !< File data.
  character(*),                  intent(in)  :: section_name    !< Section name.
  character(len=:), allocatable, intent(out) :: option_pairs(:) !< Couples option name/value [1:2].
  logical                                    :: again           !< Flag continuing the loop.
  integer(I4P)                               :: s               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  again = .false.
  s = self%index(section_name=section_name)
  if (s>0) then
    again = self%sections(s)%loop(option_pairs=option_pairs)
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction loop_options_section_file_ini

  recursive function loop_options_file_ini(self, option_pairs) result(again)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Loop returning option name/value defined into all sections.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),               intent(IN)  :: self            !< File data.
  character(len=:), allocatable, intent(OUT) :: option_pairs(:) !< Couples option name/value [1:2].
  logical                                    :: again           !< Flag continuing the loop.
  logical,      save                         :: againO=.false.  !< Flag continuing the loop.
  integer(I4P), save                         :: s=0             !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  again = .false.
  if (allocated(self%sections)) then
    if (s==0) then
      s = lbound(self%sections, dim=1)
      againO = self%loop(section_name=self%sections(s)%sname, option_pairs=option_pairs)
      again = .true.
    elseif (s<ubound(self%sections, dim=1)) then
      if (.not.againO) s = s + 1
      againO = self%loop(section_name=self%sections(s)%sname, option_pairs=option_pairs)
      if (.not.againO) then
        again = self%loop(option_pairs=option_pairs)
      else
        again = .true.
      endif
    else
      s = 0
      againO = .false.
      again = .false.
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction loop_options_file_ini

  subroutine print_file_ini(self, unit, pref, retain_comments, iostat, iomsg)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print data with a pretty format.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(in)  :: self            !< File data.
  integer(I4P),           intent(in)  :: unit            !< Logic unit.
  character(*), optional, intent(in)  :: pref            !< Prefixing string.
  logical,      optional, intent(in)  :: retain_comments !< Flag for retaining eventual comments.
  integer(I4P), optional, intent(out) :: iostat          !< IO error.
  character(*), optional, intent(out) :: iomsg           !< IO error message.
  character(len=:), allocatable       :: prefd           !< Prefixing string.
  logical                             :: rt_comm         !< Flag for retaining eventual comments.
  integer(I4P)                        :: iostatd         !< IO error.
  character(500)                      :: iomsgd          !< Temporary variable for IO error message.
  integer(I4P)                        :: s               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  rt_comm = .false. ; if (present(retain_comments)) rt_comm = retain_comments
  if (allocated(self%sections)) then
    do s=1, size(self%sections, dim=1)
      call self%sections(s)%print(pref=prefd, iostat=iostatd, iomsg=iomsgd, unit=unit, retain_comments=rt_comm)
    enddo
  endif
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_file_ini

  subroutine save_file_ini(self, retain_comments, iostat, iomsg, filename)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Save data.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini),        intent(inout) :: self            !< File data.
  logical,      optional, intent(in)    :: retain_comments !< Flag for retaining eventual comments.
  integer(I4P), optional, intent(out)   :: iostat          !< IO error.
  character(*), optional, intent(out)   :: iomsg           !< IO error message.
  character(*), optional, intent(in)    :: filename        !< File name.
  logical                               :: rt_comm         !< Flag for retaining eventual comments.
  integer(I4P)                          :: unit            !< Logic unit.
  integer(I4P)                          :: iostatd         !< IO error.
  character(500)                        :: iomsgd          !< Temporary variable for IO error message.
  integer(I4P)                          :: s               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  rt_comm = .false. ; if (present(retain_comments)) rt_comm = retain_comments
  if (present(filename)) self%filename = filename
  if (allocated(self%filename).and.allocated(self%sections)) then
    open(newunit=unit, file=self%filename, action='WRITE', iostat=iostatd, iomsg=iomsgd)
    do s=1, size(self%sections, dim=1)
      call self%sections(s)%save(iostat=iostatd, iomsg=iomsgd, unit=unit, retain_comments=rt_comm)
    enddo
    close(unit=unit, iostat=iostatd, iomsg=iomsgd)
  endif
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine save_file_ini

  elemental subroutine assign_file_ini(lhs, rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Assignment between two INI files.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(file_ini), intent(inout) :: lhs !< Left hand side.
  type(file_ini),  intent(in)    :: rhs !< Rigth hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(rhs%filename)) lhs%filename = rhs%filename
  if (allocated(rhs%sections)) then
    if (allocated(lhs%sections)) deallocate(lhs%sections) ; allocate(lhs%sections(1:size(rhs%sections, dim=1)))
    lhs%sections = rhs%sections
  endif
  lhs%Ns = rhs%Ns
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_file_ini

  subroutine file_ini_autotest()
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Autotest the library functionalities.
  !---------------------------------------------------------------------------------------------------------------------------------
  type(file_ini)                :: fini       !< INI File.
  character(len=:), allocatable :: source     !< Testing string.
  character(len=:), allocatable :: string     !< String option.
  real(R4P), allocatable        :: array(:)   !< Array option.
  integer(I4P)                  :: error      !< Error code.
  character(len=:), allocatable :: items(:,:) !< List of all options name/value couples.
  character(len=:), allocatable :: item(:)    !< Option name/value couple.
  integer(I4P)                  :: i          !< Counter.
  integer(I4P)                  :: s          !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  source='[section-1]'//new_line('A')//   &
         'option-1 = one'//new_line('A')//&
         'option-2 = 2.'//new_line('A')// &
         '           3. ; this is an inline comment'//new_line('A')// &
         'option-3 = bar ; this is an inline comment'//new_line('A')//&
         '[section-2]'//new_line('A')//   &
         'option-1 = foo'
  print "(A)", ''
  print "(A)", "Testing parsing procedures"
  print "(A)", ''
  print "(A)", "Source to be parsed:"
  print "(A)", source
  call fini%load(source=source)
  print "(A)", ''
  print "(A)", "Result of parsing:"
  string = '   '
  call fini%get(section_name='section-1', option_name='option-1', val=string, error=error)
  if (error==0) print "(A,A)", '  option-1 of section-1 has values: ', string
  allocate(array(1:fini%count_values(section_name='section-1', option_name='option-2')))
  call fini%get(section_name='section-1', option_name='option-2', val=array, error=error)
  if (error==0) print "(A,3(F4.1,1X))", '  option-2 of section-1 has values: ', array
  call fini%get(section_name='section-1', option_name='option-3', val=string, error=error)
  if (error==0) print "(A,A)", '  option-3 of section-1 has values: ', string
  call fini%get(section_name='section-2',option_name='option-1', val=string, error=error)
  if (error==0) print "(A,A)", '  option-1 of section-2 has values: ', string
  print "(A)", ''
  print "(A)", "Parsed data will be saved as (having retained inline comments that are trimmed out by default):"
  call fini%print(pref='  ', unit=stdout, retain_comments=.true.)
  call fini%save(filename='foo.ini', retain_comments=.true.)
  call fini%free
  print "(A)", ''
  print "(A)", "Testing generating procedures"
  call fini%add(section_name='sec-foo')
  call fini%add(section_name='sec-foo', option_name='bar', val=-32.1_R8P)
  call fini%add(section_name='sec-foo', option_name='baz', val=' hello FiNeR! ')
  call fini%add(section_name='sec-foo', option_name='array', val=[1, 2, 3, 4])
  call fini%add(section_name='sec-bar')
  call fini%add(section_name='sec-bar', option_name='bools', val=[.true.,.false.,.false.])
  call fini%add(section_name='sec-bartolomeo')
  call fini%add(section_name='sec-bartolomeo', option_name='help', val='I am Bartolomeo')
  print "(A)", "The autogenerated INI file will be saved as:"
  call fini%print(pref='  ', unit=stdout)
  print "(A)", ''
  print "(A)", "Testing removing option baz"
  call fini%del(section_name='sec-foo', option_name='baz')
  call fini%print(pref='  ', unit=stdout)
  print "(A)", ''
  print "(A)", "Testing removing section sec-bar"
  call fini%del(section_name='sec-bar')
  call fini%print(pref='  ', unit=stdout)
  print "(A)", ''
  print "(A)", "Testing introspective methods"
  print "(A,L1)", "Is there option bar? ", fini%has_option(option_name='bar')
  print "(A,L1)", "Is there option baz? ", fini%has_option(option_name='baz')
  print "(A,L1)", "Is there section sec-bar? ", fini%has_section(section_name='sec-bar')
  print "(A,L1)", "Is there section sec-foo? ", fini%has_section(section_name='sec-foo')
  print "(A)", ''
  print "(A)", "What are all options name/values couples? Can I have a list? Yes, you can:"
  items = fini%items()
  do i=1, size(items, dim=1)
    print "(A)", trim(items(i, 1))//' = '//trim(items(i, 2))
  enddo
  print "(A)", ''
  print "(A)", "Testing loop method over options of a section:"
  do s=1, fini%Ns
    print "(A)", fini%section(s)
    do while(fini%loop(section_name=fini%section(s), option_pairs=item))
      print "(A)", '  '//trim(item(1))//' = '//trim(item(2))
    enddo
  enddo
  print "(A)", ''
  print "(A)", "Testing loop method over all options:"
  do while(fini%loop(option_pairs=item))
    print "(A)", '  '//trim(item(1))//' = '//trim(item(2))
  enddo
  print "(A)", ''
  print "(A)", "Testing custom separator of option name/value:, use ':' instead of '='"
  source='[section-1]'//new_line('A')//   &
         'option-1 : one'//new_line('A')//&
         'option-2 : 2.'//new_line('A')// &
         '           3.'//new_line('A')// &
         'option-3 : bar'//new_line('A')//&
         '[section-2]'//new_line('A')//   &
         'option-1 : foo'
  print "(A)", ''
  print "(A)", "Source to be parsed:"
  print "(A)", source
  call fini%free
  call fini%load(separator=':', source=source)
  print "(A)", ''
  print "(A)", "Result of parsing:"
  call fini%print(pref='  ', unit=stdout)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine file_ini_autotest
endmodule finer_file_ini_t