#pkowalewski & gkulikovskis
.text
    no_file_string: .asciz "No filename specified"
    syntax_error: .asciz "Brackets don't match"
    format_string_nl: .asciz "%s\n"

# linux syscalls
.equ sys_read, 0
.equ sys_write, 1
.equ sys_open, 2
.equ sys_close, 3
.equ sys_exit, 60

.lcomm file_descriptor, 1
.lcomm file_name_address, 8
.lcomm file_buffer, 102400

.lcomm cells, 30001


.data
    i: .quad 0
    input: .byte 0
    pointer: .quad 0

.global main
main:
    pushq	%rbp      # CREATE NEW STACK FRAME
	movq	%rsp, %rbp # CREATE NEW STACK FRAME

    cmpq $1, %rdi
    je no_file_errormsg

    ## LOAD FILE
    movq	%rsi, %rax
	addq	$8, %rax  # first argument is actually the second one because the first one is executable name
	movq	(%rax), %rax
	movq	%rax, (file_name_address) # save first argument's address to a variable

    movq	$sys_open, %rax
	movq	(file_name_address), %rdi # address of first file
	movq	$0, %rsi # open mode : read only
	syscall

	movq	%rax, (file_descriptor) # save file descriptor to memory

    movq	$sys_read, %rax # read file from file descriptor and save it to the memory
	movq	(file_descriptor), %rdi
	movq	$file_buffer, %rsi # file1_buffer is where we will store our file
	movq	$102400, %rdx # we set max. file size to 100KB
	syscall


	movq	$sys_close, %rax # close the file
	movq	(file_descriptor), %rdi
    syscall
    ## END LOADING FILE


movq $cells, %rsi #zero all cells (30000)
zero_loop:
    movb $0, (%rsi) #zero cell

    incq %rsi #pointer++
    incq (i)  #i++
    cmpq $30001, (i) #i <= 30000 => iterate the loop
    jl zero_loop


    movq $0, (i) #reset loop iterator
    call brainfuck #call bf subroutine

    

end:
    movq %rbp, %rsp
    popq %rbp #restore old stack frame
	movq $sys_exit, %rax #sys_exit
	movq $0, %rdi
    syscall


no_file_errormsg: #error shown where no file was specifed
    movq $0, %rax
    movq $no_file_string, %rsi
    movq $format_string_nl, %rdi
    call printf #print the msh
    jmp end #end the programme

syntax_errormsg: #error shown when the brackets weren't symetric
    movq %rbp, %rsp
    popq %rbp #restore main's stack frame
    
    movq $0, %rax
    movq $syntax_error, %rsi
    movq $format_string_nl, %rdi
    call printf #print the msg

    ret #return from bf subroutine


brainfuck:
    pushq	%rbp      # CREATE NEW STACK FRAME
	movq	%rsp, %rbp # CREATE NEW STACK FRAME

    movq $0, (i) #i shows on which character of the file we're working on atm
    movq $file_buffer, %rsi 
main_loop:
    cmpb $0, (%rsi) #if file ended => end the loop
    je _main_loop_end 

#Process single char
    handle_greater: # >
        cmpb $'>', (%rsi)
        jne handle_less

        incq (pointer) #increase pointer

        jmp continue
    handle_less: # <
        cmpb $'<', (%rsi)
        jne handle_plus

        decq (pointer) #decrease pointer

        jmp continue
    handle_plus: # +
        cmpb $'+', (%rsi)
        jne handle_minus

        movq $cells, %rsi 
        addq (pointer), %rsi #address of the cell array + current character index
        incq (%rsi) #add 1 to memory cell under current pointer

        jmp continue
    handle_minus: # -
        cmpb $'-', (%rsi)
        jne handle_dot

        movq $cells, %rsi
        addq (pointer), %rsi #address of the cell array + current character index
        decq (%rsi) #substract 1 from memory cell under current pointer

        jmp continue
    handle_dot: # .
        cmpb $'.', (%rsi)
        jne handle_comma

        #print character under current pointer
        movq $cells, %rsi
        addq (pointer), %rsi
        movq $sys_write, %rax
        movq $1, %rdi
        movq $1, %rdx 
        syscall

        jmp continue
    handle_comma: # ,
        cmpb $',', (%rsi)
        jne handle_open_bracket

        #read one character
        movq $input, %rsi
        movq $sys_read, %rax
        movq $1, %rdi
        movq $1, %rdx
        syscall
        #put it under the pointer
        movq $cells, %rsi
        addq (pointer), %rsi
        movb (input), %al
        movb %al, (%rsi)

        jmp continue
    handle_open_bracket: # [
        cmpb $'[', (%rsi)
        jne handle_close_bracket

        movq $cells, %rsi
        addq (pointer), %rsi
        cmpb $0, (%rsi)
        jne handle_open_bracket_nonzero
        handle_open_bracket_zero:
            #jump past matching ]
            movq $1, %r9
        handle_open_bracket_zero_loop:
            incq (i)
            movq (i), %rax
            movq $file_buffer, %rsi
            addq %rax, %rsi
            #eof -> bad syntax
            cmpb $0, (%rsi)
            je syntax_errormsg
            #new [
            cmpb $'[', (%rsi)
            jne handle_open_bracket_zero_loop_check_cb
            incq %r9
            jmp handle_open_bracket_zero_loop_while
            #new ]
            handle_open_bracket_zero_loop_check_cb:
            cmpb $']', (%rsi)
            jne handle_open_bracket_zero_loop_while
            decq %r9
            handle_open_bracket_zero_loop_while:
            cmpq $0, %r9 #when numner of read [ and ] is equal, then we found the mathing one -> continue
            jne handle_open_bracket_zero_loop
            
            jmp continue
        handle_open_bracket_nonzero:
            #save [ pointer on stack, continue
            pushq (i)
            jmp continue
    handle_close_bracket: # ]
        cmpb $']', (%rsi)
        jne continue #character is not implemented -> go to the next one

        movq $cells, %rsi
        addq (pointer), %rsi
        cmpb $0, (%rsi)
        jne handle_close_bracket_nonzero
        handle_close_bracket_zero:
            #continue
            popq %r15 #remove matching [ from the stack
            jmp continue
        handle_close_bracket_nonzero:
            #go back to matching [
            popq (i) #go back to the matching [
            decq (i)

            jmp continue
   

continue:
    incq (i)
    movq (i), %rax
    movq $file_buffer, %rsi
    addq %rax, %rsi
    jmp main_loop
_main_loop_end:
    movq %rbp, %rsp
    popq %rbp

    ret
