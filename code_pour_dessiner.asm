; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XDrawArc
extern XFillArc
extern XNextEvent
extern XStoreName

extern exit

extern printf

%define StructureNotifyMask 131072
%define KeyPressMask        1
%define ButtonPressMask     4
%define MapNotify           19
%define KeyPress            2
%define ButtonPress         4
%define Expose              12
%define ConfigureNotify     22
%define CreateNotify        16
%define QWORD               8
%define DWORD               4
%define WORD                2
%define BYTE                1
%define NBTRI               1
%define BYTE                1
%define LARGEUR             400 ; largeur en pixels de la fenêtre
%define HAUTEUR             400 ; hauteur en pixels de la fenêtre

%define POINT_COUNT 100

global main

section .bss
display_name: resq 1
screen:       resd 1
depth:        resd 1
connection:   resd 1
width:        resd 1
height:       resd 1
window:       resq 1
gc:           resq 1

points_x:    resd POINT_COUNT
points_y:    resd POINT_COUNT
point_set_H: resd POINT_COUNT
point_Pi:    resd 1
point_Qi:    resd 1
point_Ii:    resd 1

section .data
event: times 24 dq 0

printf_debug:              db "point %u: %u %u",10,0
printf_debug_jarvis_add_p: db "point at H[%u]: (i:%u x:%u y:%u)",10,0
printf_debug_leftmost:     db 10,"leftmost point: i=%u x=%u",10,0

window_title: db "Algorithme de Jarvis",0

leftmost_point_i: dd 0
leftmost_point_x: dd LARGEUR
point_set_H_i: db 0

section .text

; gets a random integer between 0 and rcx
; param: rcx: the max of the rand
; return: rdx: the generated integer
get_rand_int:
  rdrand rax
  pushf
  xor rdx,rdx
  div rcx
  popf
  ret

; draws a circle based on the values stored in points_x points_y
; param: edi: x pos
; param: esi: y pos
draw_circle:
  mov ecx,edi ; coodonnée en X
  sub ecx,3

  mov r8d,esi ; coodonnée en Y
  sub r8d,3

  mov rdi,qword[display_name]
  mov rsi,qword[window]
  mov rdx,qword[gc]

  mov  r9,6
  mov  rax,23040
  push rax
  push 0
  push r9
  call XFillArc
  add  rsp,24
  ret

; computes the cross product of AB and BC
; param: edi: x1
; param: esi: y1
; param: edx: x2
; param: ecx: y2
; param: r8d: x3
; param: r9d: y3
; return: eax: the cross product
cross_product:
  mov eax, edx
  mov r12d,ecx
  mov r13d,edi
  mov r14d,esi

  sub r14d,r12d
  sub r13d,eax
  sub r12d,r9d
  sub eax, r8d

  mul eax, r14d
  mul r12d,r13d

  sub eax,r12d

  ret

; draw a line between two point indices
; param: r12: index of first point
; param: r13: index of second point
draw_line:
  mov rdi, qword[display_name]
  mov rsi, qword[window]
  mov rdx, qword[gc]
  mov ecx, dword[points_x+r12d*DWORD] ; coordonnée source en x
  mov r8d, dword[points_y+r12d*DWORD] ; coordonnée source en y
  mov r9d, dword[points_x+r13d*DWORD] ; coordonnée destination en x
  mov r14d,dword[points_y+r13d*DWORD]
  push r14                            ; coordonnée destination en y
  call XDrawLine
  add rsp,8
  ret

;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
  ; Sauvegarde du registre de base pour préparer les appels à printf
  push rbp
  mov  rbp, rsp

  ; Récupère le nom du display par défaut (en passant NULL)
  xor  rdi, rdi          ; rdi = 0 (NULL)
  call XDisplayName      ; Appel de la fonction XDisplayName
  ; Vérifie si le display est valide
  test rax, rax          ; Teste si rax est NULL
  jz   closeDisplay      ; Si NULL, ferme le display et quitte

  ; Ouvre le display par défaut
  xor  rdi, rdi          ; rdi = 0 (NULL pour le display par défaut)
  call XOpenDisplay      ; Appel de XOpenDisplay
  test rax, rax          ; Vérifie si l'ouverture a réussi
  jz   closeDisplay      ; Si échec, ferme le display et quitte

  ; Stocke le display ouvert dans la variable globale display_name
  mov  qword[display_name], rax

  ; Récupère la fenêtre racine (root window) du display
  mov  rdi,qword[display_name] ; Place le display dans rdi
  mov  esi,dword[screen]       ; Place le numéro d'écran dans esi
  call XRootWindow             ; Appel de XRootWindow pour obtenir la fenêtre racine
  mov  rbx,rax                 ; Stocke la root window dans rbx

  ; Création d'une fenêtre simple
  mov  rdi,qword[display_name] ; display
  mov  rsi,rbx                 ; parent = root window
  mov  rdx,10                  ; position x de la fenêtre
  mov  rcx,10                  ; position y de la fenêtre
  mov  r8,LARGEUR              ; largeur de la fenêtre
  mov  r9,HAUTEUR              ; hauteur de la fenêtre
  push 0xFFFFFF                ; couleur du fond (noir, 0x000000)
  push 0x00FF00                ; couleur de fond (vert, 0x00FF00)
  push 1                       ; épaisseur du bord
  call XCreateSimpleWindow     ; Appel de XCreateSimpleWindow

  add  rsp,24
  mov  qword[window],rax       ; Stocke l'identifiant de la fenêtre créée dans window

  ; sets the windows title
  mov  rdi,qword[display_name]
  mov  rsi,qword[window]
  mov  rdx,window_title
  call XStoreName

  ; Sélection des événements à écouter sur la fenêtre
  mov  rdi,qword[display_name]
  mov  rsi,qword[window]
  mov  rdx,131077              ; Masque d'événements (ex. StructureNotifyMask + autres)
  call XSelectInput

  ; Affichage (mapping) de la fenêtre
  mov  rdi,qword[display_name]
  mov  rsi,qword[window]
  call XMapWindow

  ; Création du contexte graphique (GC) avec vérification d'erreur
  mov  rdi, qword[display_name]
  test rdi, rdi                ; Vérifie que display n'est pas NULL
  jz   closeDisplay

  mov  rsi, qword[window]
  test rsi, rsi                ; Vérifie que window n'est pas NULL
  jz   closeDisplay

  xor  rdx, rdx                ; Aucun masque particulier
  xor  rcx, rcx                ; Aucune valeur particulière
  call XCreateGC               ; Appel de XCreateGC pour créer le contexte graphique
  test rax, rax                ; Vérifie la création du GC
  jz   closeDisplay            ; Si échec, quitte
  mov  qword[gc], rax          ; Stocke le GC dans la variable gc

  ; init POINT_COUNT random points in points_x/y
  mov ebx,0
  while_init_points:
    cmp ebx,POINT_COUNT
    jge end_while_init_points

    ; put a random int in points_x
    mov rcx,LARGEUR-80                   ; the max of the random (-80 to account for padding)
    call get_rand_int                    ; generate random number
    jnc end_while_init_points            ; CF=0 so the random value is invalid
    add edx,40                           ; left padding
    mov dword[points_x+rbx*DWORD],edx    ; store the random value

    ; put a random int in points_y
    mov rcx,HAUTEUR-80                   ; the max of the random (-80 to account for padding)
    call get_rand_int                    ; generate random number
    jnc end_while_init_points            ; CF=0 so the random value is invalid
    add edx,40                           ; top padding
    mov dword[points_y+rbx*DWORD],edx    ; store the random value

    ; print the point and its index
    mov rdi,printf_debug
    mov esi,ebx
    mov edx,dword[points_x+rbx*DWORD]
    mov ecx,dword[points_y+rbx*DWORD]
    mov rax,0
    call printf

    ; find the leftmost point
    mov eax,dword[points_x+rbx*DWORD]
    cmp eax,dword[leftmost_point_x]
    jge skip_point
       mov dword[leftmost_point_x],eax
       mov dword[leftmost_point_i],ebx
    skip_point:

    inc ebx
    jmp while_init_points
  end_while_init_points:

  ; print the leftmost point and it's index
  mov rdi,printf_debug_leftmost
  mov esi,dword[leftmost_point_i]
  mov edx,dword[leftmost_point_x]
  xor rax,rax
  call printf

  ; Pi <- Li
  mov eax,dword[leftmost_point_i]
  mov dword[point_Pi],eax

  while_jarvis:
    ; add P to H
    mov eax,dword[point_Pi]
    mov ecx,dword[point_set_H_i]
    mov [point_set_H+ecx*DWORD],eax

    ; print the info of the add
    mov rdi,printf_debug_jarvis_add_p
    mov esi,dword[point_set_H_i]
    mov edx,dword[point_Pi]
    mov ecx,dword[point_Pi]
    mov ecx,dword[points_x+ecx*DWORD]
    mov r8d,dword[point_Pi]
    mov r8d,dword[points_y+r8d*DWORD]
    xor rax,rax
    call printf

    ; Q is the point after P in E ( Q=E[P+1] )
    mov ecx,POINT_COUNT
    mov eax,dword[point_Pi]
    inc eax
    xor edx,edx
    div ecx
    mov dword[point_Qi],edx ; point_Qi = (Pi+1) % sz

    ; foreach I in E that is not P or Q
    mov dword[point_Ii],0
    foreach_i:
      mov eax,dword[point_Ii]
      ; break when we reach the end
      cmp eax,POINT_COUNT
      jge end_foreach_i

      ; continue if I is Q
      cmp eax,dword[point_Qi]
      je continue_foreach_i

      ; continue if I is P
      cmp eax,dword[point_Pi]
      je continue_foreach_i

      ; get the winding direction of triangle PIQ
      mov eax,dword[point_Pi]
      mov edi,dword[points_x+eax*DWORD]
      mov esi,dword[points_y+eax*DWORD]
      mov eax,dword[point_Qi]
      mov edx,dword[points_x+eax*DWORD]
      mov ecx,dword[points_y+eax*DWORD]
      mov eax,dword[point_Ii]
      mov r8d,dword[points_x+eax*DWORD]
      mov r9d,dword[points_y+eax*DWORD]
      call cross_product
    
      ; if the triangle goes clockwise
      cmp eax,0
      jle continue_foreach_i
        ; Q <- I
        mov edx,dword[point_Ii]
        mov dword[point_Qi],edx

      continue_foreach_i:
      inc dword[point_Ii]
      jmp foreach_i
    end_foreach_i:

    ; P <- Q
    mov ecx,dword[point_Qi]
    mov dword[point_Pi],ecx

    inc dword[point_set_H_i]

    ; if P==L we're done
    mov eax,dword[point_Pi]
    cmp dword[leftmost_point_i],eax
    je end_while_jarvis

    jmp while_jarvis
  end_while_jarvis:

  boucle: ; Boucle de gestion des événements
    mov     rdi, qword[display_name]
    cmp     rdi, 0              ; Vérifie que le display est toujours valide
    je      closeDisplay        ; Si non, quitte
    mov     rsi, event          ; Passe l'adresse de la structure d'événement
    call    XNextEvent          ; Attend et récupère le prochain événement
  
    cmp     dword[event], ConfigureNotify ; Si l'événement est ConfigureNotify (ex: redimensionnement)
    je      dessin                        ; Passe à la phase de dessin
  
    cmp     dword[event], KeyPress        ; Si une touche est pressée
    je      closeDisplay                  ; Quitte le programme
    jmp     boucle                        ; Sinon, recommence la boucle


;#########################################
;#      DEBUT DE LA ZONE DE DESSIN       #
;#########################################
dessin:

  ; Changer la couleur de dessin
  mov rdi,qword[display_name]
  mov rsi,qword[gc]
  mov edx,0x000000 ; black
  call XSetForeground

  ; draw lines between all points of H
  xor ebx,ebx
  while_draw_lines:
    ; stop when ebx >= len(H) - 1
    mov eax,dword[point_set_H_i]
    dec eax
    cmp ebx,eax
    jge end_while_draw_lines

    ; eax : index of H+1
    ; ebx : index of H
    ; r12 : H[ebx]
    ; r13 : H[ebx + 1]
    mov eax,ebx
    inc eax
    mov r12d,dword[point_set_H+ebx*DWORD]
    mov r13d,dword[point_set_H+eax*DWORD]
    call draw_line

    inc ebx
    jmp while_draw_lines
  end_while_draw_lines:

  ; close the hull with the last line to H[0]
  mov r12d,dword[point_set_H+ebx*DWORD]
  mov r13d,dword[point_set_H+0*DWORD]
  call draw_line

  ; draw every point
  xor rbx,rbx
  while_draw_points:
    cmp rbx,POINT_COUNT
    jge end_while_draw_points

    mov edi,dword[points_x+rbx*DWORD]
    mov esi,dword[points_y+rbx*DWORD]
    call draw_circle

    inc rbx
    jmp while_draw_points
  end_while_draw_points:


; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
  mov  rax,qword[display_name]
  mov  rdi,rax
  call XCloseDisplay
  xor  rdi,rdi
  call exit

