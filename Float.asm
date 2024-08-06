;;; Author: Lawrence Menegus
;;; File: Float.asm
;;; Date: 4/25/23
;;; Description: Create an Inventory system using a linked list and floating point values

%define EOF -1
%define empty 0
%define NuLL 0

struc Product
    .ProductID: resd 1
    .name: resq 26
    .price: resq 1
    .cost: resq 1
    .quantity: resd 1
    .redptr: resq 1
    .size:
endstruc

segment .data
;; Display Prompts
prompt: db "Welcome to Smith's Seed Inventory Control System! ", 0
prompt2: db "Please have a Product Number, Product Name, Price, Cost and Quantity information ready.", 0
promptNumber: db "Enter Product ID: ", 0
promptName: db "Enter Product Name: ", 0
promptPrice: db "Enter the Price: ", 0
promptCost: db "Enter the Cost: ", 0
promptQuantity: db "Enter the Quantity: ", 0
new: db "", 10,10, 0

;; Output Prompts
promptResponse: db "Here is the current store inventory:", 0
outputNumber: db "Product ID: %d", 10, 0
outputName: db "Product Name: %s", 10, 0
outputPrice: db "Price: $%.2lf", 10, 0
outputCost: db "Cost: $%.2lf", 10, 0
outputQuantity: db "Quantity: %d", 10, 0
outputInventoryQuantity: db "Total Inventory Quantity: %d", 10, 0
outputInventoryAssets: db "Total Inventory Assets: $%.2lf", 10, 0
outputLiability: db "Total Inventory Liability: $%.2lf", 10, 0

intFormat: db "%d", 0
strFormat: db "%s", 0
floatFormat: db "%lf", 0

segment .bss
;; Points to the head of the linked list
head: resq 1
;; Points to last node
lastNode: resq 1
intInput: resd 1
floatInput: resq 1
strInput: resb 255
totalQuantity: resd 1
totalVal: resq 1
tempVal: resq 1
totalCost: resq 1
tempCost: resq 1

segment .text
global asm_main
extern printf, scanf, calloc, free, strncpy, strnlen

asm_main:
    enter 8, 0
    ;; Initialize Totals
    mov [totalQuantity], dword 0
    mov [totalVal], dword 0
    mov [totalVal + 4], dword 0
    mov [totalCost], dword 0
    mov [totalCost + 4], dword 0
    ;; Align stack
    sub rsp, 8
    ;; Print out Greeting Prompts
    mov rdi, new
    call printf
    mov rdi, prompt
    call printf
    mov rdi, new
    call printf
    mov rdi, prompt2
    call printf
    mov rdi, new
    call printf
    add rsp, 8
    call Input
    ;; Move pointer to linked list's head to rdi
    mov rdi, rax
    call Output
    mov rax, 0
    leave
    ret

Input:
    enter 8, 0
    ;; Clear registers
    xor r8, r8
    xor r12, r12
    xor r13, r13
    xor r14, r14

inputLoop:
    push rcx
    push rsi
    ;; Create the head node
    cmp r13, BYTE empty
    jne newNode
    ;; Allocate space for head node of the linked list
    mov rdi, 1
    mov rsi, Product.size
    call calloc
    ;; Move head and last node
    mov r14, rax
    mov r13, rax
    jmp AddtoNode

newNode:
    ;; Allocate space
    mov rdi, 1
    mov rsi, Product.size
    call calloc
    ;; Move lastNode
    mov r12, r13
    mov [r12 + Product.redptr], rax
    mov r13, rax
    jmp AddtoNode

AddtoNode:
    ;; Product ID
    mov rdi, promptNumber
    call printf
    mov rdi, intFormat
    mov rsi, intInput
    call scanf
    ;; If the Control D is pressed, it jumps to end of the input
    cmp eax, EOF
    jne Continue
    ;; Clears the pointer
    ;; r12 holds the previous node
    xor r9, r9
    mov [r12 + Product.redptr], r9
    jmp endInput

Continue:
    ;; Move the value into the struct's location
    mov rax, [intInput]
    mov [r13 + Product.ProductID], eax
    ;; Display to the user to ask for product name
    mov rdi, promptName
    call printf
    ;; Return user input
    mov rdi, strFormat
    mov rsi, strInput
    call scanf
    ;; Get string length
    mov rdi, strInput
    mov rsi, 255
    call strnlen
    inc rax
    mov r15, rax
    ;; Allocate memory for string
    mov rdi, rax
    mov rsi, 1
    call calloc
    ;; Copy string to node's location
    mov [r13 + Product.name], rax
    mov rdi, rax
    mov rsi, strInput
    mov rdx, r15
    call strncpy
    ;; Product Price
    mov rdi, promptPrice
    call printf
    mov rax, 1
    mov rdi, floatFormat
    mov rsi, floatInput
    call scanf
    ;; Store double in Temporary Value
    movq [r13 + Product.price], xmm0
    movq [tempVal], xmm0
    ;; Product Cost
    mov rdi, promptCost
    call printf
    mov rdi, floatFormat
    mov rsi, floatInput
    call scanf
    movq [r13 + Product.cost], xmm0
    movq [tempCost], xmm0
    ;; Product Quantity
    mov rdi, promptQuantity
    call printf
    mov rdi, intFormat
    mov rsi, intInput
    call scanf
    ;; Move the value into the struct's location
    mov rax, [intInput]
    mov [r13 + Product.quantity], eax
    ;; Add value to Total Quantity
    mov r15, rax
    add eax, [totalQuantity]
    mov [totalQuantity], eax
    ;; Calculate Liability
    cvtsi2sd xmm1, r15d
    movsd xmm0, qword [tempCost]
    mulsd xmm0, xmm1
    movsd xmm2, qword [totalCost]
    addsd xmm0, xmm2
    movsd [totalCost], xmm0
    ;; Calculate Assets
    cvtsi2sd xmm1, r15d
    movsd xmm0, qword [tempVal]
    mulsd xmm0, xmm1
    movsd xmm2, qword [totalVal]
    addsd xmm0, xmm2
    movsd [totalVal], xmm0
    mov rdi, new
    call printf
    jmp inputLoop

endInput:
    mov rax, r14
    leave
    ret

Output:
    enter 8, 0
    mov r13, rdi

outputLoop:
    push rcx
    push rsi
    mov rdi, outputNumber
    mov eax, [r13 + Product.ProductID]
    mov rsi, rax
    call printf
    mov rdi, outputName
    mov rax, [r13 + Product.name]
    mov rsi, rax
    call printf
    mov rdi, outputPrice
    movsd xmm0, [r13 + Product.price]
    mov rax, 1
    call printf
    mov rdi, outputCost
    movsd xmm0, [r13 + Product.cost]
    mov rax, 1
    call printf
    mov rdi, outputQuantity
    mov eax, [r13 + Product.quantity]
    mov rsi, rax
    call printf
    mov rdi, new
    call printf
    ;; Move to next node
    mov r13, [r13 + Product.redptr]
    pop rsi
    pop rcx
    cmp r13, NuLL
    jne outputLoop

    ;; Print out Inventory totals of Quantity, Assets and Liability
    mov rdi, outputInventoryQuantity
    mov esi, dword [totalQuantity]
    call printf
    mov rdi, outputInventoryAssets
    mov rax, 1
    movsd xmm0, qword [totalVal]
    call printf
    mov rdi, outputLiability
    mov rax, 1
    movsd xmm0, qword [totalCost]
    call printf

    leave
    ret