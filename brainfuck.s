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
.lcomm file_buffer, 10240

.lcomm cells, 30000


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
	movq	$10240, %rdx # we set max. file size to 10KB
	syscall


	movq	$sys_close, %rax # close the file
	movq	(file_descriptor), %rdi
    syscall
    ## END LOADING FILE


movq $cells, %rsi
zero_loop:
    movb $0, (%rsi)

    incq %rsi
    incq (i)
    cmpq $30000, (i)
    jl zero_loop


    movq $0, (i)
    call brainfuck

    

end:
    movq %rbp, %rsp
    popq %rbp
	movq	$sys_exit, %rax # CALL SYSTEM EXIT
	movq	$0, %rdi
    syscall


no_file_errormsg:
    movq $0, %rax
    movq $no_file_string, %rsi
    movq $format_string_nl, %rdi
    call printf
    jmp end

syntax_errormsg:
    movq %rbp, %rsp
    popq %rbp
    
    movq $0, %rax
    movq $syntax_error, %rsi
    movq $format_string_nl, %rdi
    call printf

    ret


brainfuck:
    pushq	%rbp      # CREATE NEW STACK FRAME
	movq	%rsp, %rbp # CREATE NEW STACK FRAME

    movq $0, (i)
    movq $file_buffer, %rsi
main_loop:
    cmpb $0, (%rsi)
    je _main_loop_end

#Process single char
    handle_greater:
        cmpb $'>', (%rsi)
        jne handle_less

        incq (pointer)

        jmp continue
    handle_less:
        cmpb $'<', (%rsi)
        jne handle_plus

        decq (pointer)

        jmp continue
    handle_plus:
        cmpb $'+', (%rsi)
        jne handle_minus

        movq $cells, %rsi
        addq (pointer), %rsi
        incq (%rsi)

        jmp continue
    handle_minus:
        cmpb $'-', (%rsi)
        jne handle_dot

        movq $cells, %rsi
        addq (pointer), %rsi
        decq (%rsi)

        jmp continue
    handle_dot:
        cmpb $'.', (%rsi)
        jne handle_comma

        movq $cells, %rsi
        addq (pointer), %rsi
        movq $sys_write, %rax
        movq $1, %rdi
        movq $1, %rdx
        syscall

        jmp continue
    handle_comma:
        cmpb $',', (%rsi)
        jne handle_open_bracket

        movq $cells, %rsi
        addq (pointer), %rsi
        movq $sys_read, %rax
        movq $1, %rdi
        movq $1, %rdx
        syscall

        jmp continue
    handle_open_bracket:
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
            decq %r9
            handle_open_bracket_zero_loop_while:
            cmpq $0, %r9
            jne handle_open_bracket_zero_loop
            
            jmp continue
        handle_open_bracket_nonzero:
            #save [ pointer on stack, continue
            pushq (i)
            jmp continue
    handle_close_bracket:
        cmpb $']', (%rsi)
        jne continue

        movq $cells, %rsi
        addq (pointer), %rsi
        cmpb $0, (%rsi)
        jne handle_close_bracket_nonzero
        handle_close_bracket_zero:
            #continue
            jmp continue
        handle_close_bracket_nonzero:
            #go back to matching [
            popq (i)
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
