.text
    no_file_string: .asciz "No filename specified"
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

.lcomm i, 0

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
	movq	$file_descriptor, %rdi
    syscall
    ## END LOADING FILE
l:

    movq $file_buffer, %rsi
    addq (i), %rsi

    movq	$sys_write, %rax
	movq	$1, %rdi
	movq	$1, %rdx
    syscall

    incq (i)
    cmpq $10, (i)
    jl l

    

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
