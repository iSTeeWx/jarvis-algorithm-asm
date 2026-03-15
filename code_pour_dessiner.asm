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

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1
%define NBTRI	1
%define BYTE	1
%define	LARGEUR 400	; largeur en pixels de la fenêtre
%define HAUTEUR 400	; hauteur en pixels de la fenêtre

%define POINT_COUNT 10

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
points_x:     resd POINT_COUNT
points_y:     resd POINT_COUNT

section .data
event: times 24 dq 0
x1: dd 0
x2: dd 0
y1: dd 0
y2: dd 0
printf_debug: db "point %u: %u %u",10,0
printf_debug_leftmost: db 10,"leftmost point: i=%u x=%u",10,0
window_title: db "Algorithme de Jarvis",0

leftmost_point_i: dd 0
leftmost_point_x: dd LARGEUR

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
; param: rbx: the index of the circle to draw
draw_circle:
  ; Dessin d'un point sous forme de petit rond
  mov rdi,qword[display_name]
  mov rsi,qword[window]
  mov rdx,qword[gc]

  mov rcx,[points_x+rbx*DWORD] ; coodonnée en X
  sub rcx,3

  mov r8,[points_y+rbx*DWORD] ; coodonnée en Y
  sub r8,3

  mov r9,6
  mov rax,23040
  push rax
  push 0
  push r9
  call XFillArc
  add rsp,24
  ; Fin de dessin d'un point sous forme de petit rond
  ret
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
    ; Sauvegarde du registre de base pour préparer les appels à printf
    push    rbp
    mov     rbp, rsp
	
    ; Récupère le nom du display par défaut (en passant NULL)
    xor     rdi, rdi          ; rdi = 0 (NULL)
    call    XDisplayName      ; Appel de la fonction XDisplayName
    ; Vérifie si le display est valide
    test    rax, rax          ; Teste si rax est NULL
    jz      closeDisplay      ; Si NULL, ferme le display et quitte

    ; Ouvre le display par défaut
    xor     rdi, rdi          ; rdi = 0 (NULL pour le display par défaut)
    call    XOpenDisplay      ; Appel de XOpenDisplay
    test    rax, rax          ; Vérifie si l'ouverture a réussi
    jz      closeDisplay      ; Si échec, ferme le display et quitte

    ; Stocke le display ouvert dans la variable globale display_name
    mov     qword[display_name], rax

    ; Récupère la fenêtre racine (root window) du display
    mov     rdi,qword[display_name]   ; Place le display dans rdi
    mov     esi,dword[screen]         ; Place le numéro d'écran dans esi
    call    XRootWindow               ; Appel de XRootWindow pour obtenir la fenêtre racine
    mov     rbx,rax                   ; Stocke la root window dans rbx

    ; Création d'une fenêtre simple
    mov     rdi,qword[display_name]   ; display
    mov     rsi,rbx                   ; parent = root window
    mov     rdx,10                    ; position x de la fenêtre
    mov     rcx,10                    ; position y de la fenêtre
    mov     r8,LARGEUR                ; largeur de la fenêtre
    mov     r9,HAUTEUR           	    ; hauteur de la fenêtre
    push 0xFFFFFF                     ; couleur du fond (noir, 0x000000)
    push 0x00FF00                     ; couleur de fond (vert, 0x00FF00)
    push 1                            ; épaisseur du bord
    call XCreateSimpleWindow          ; Appel de XCreateSimpleWindow

	  add rsp,24
	  mov qword[window],rax           ; Stocke l'identifiant de la fenêtre créée dans window

    ; sets the windows title
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,window_title
    call XStoreName

    ; Sélection des événements à écouter sur la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,131077                 ; Masque d'événements (ex. StructureNotifyMask + autres)
    call XSelectInput

    ; Affichage (mapping) de la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    call XMapWindow

    ; Création du contexte graphique (GC) avec vérification d'erreur
    mov rdi, qword[display_name]
    test rdi, rdi                ; Vérifie que display n'est pas NULL
    jz closeDisplay

    mov rsi, qword[window]
    test rsi, rsi                ; Vérifie que window n'est pas NULL
    jz closeDisplay

    xor rdx, rdx                 ; Aucun masque particulier
    xor rcx, rcx                 ; Aucune valeur particulière
    call XCreateGC               ; Appel de XCreateGC pour créer le contexte graphique
    test rax, rax                ; Vérifie la création du GC
    jz closeDisplay              ; Si échec, quitte
    mov qword[gc], rax           ; Stocke le GC dans la variable gc

    mov ebx,0
    while_init_points:
      cmp ebx,POINT_COUNT
      jge end_while_init_points

      mov rcx,LARGEUR-80                   ; the max of the random (-80 to account for padding)
      call get_rand_int                    ; generate random number
      jnc end_while_init_points            ; CF=0 so the random value is invalid
      add edx,40                           ; left padding
      mov dword[points_x+rbx*DWORD],edx    ; store the random value

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

      mov eax,dword[points_x+rbx*DWORD]
      cmp eax,dword[leftmost_point_x]
      jge skip_point
         mov dword[leftmost_point_x],eax
         mov dword[leftmost_point_i],ebx
      skip_point:

      inc ebx
      jmp while_init_points
    end_while_init_points:

    mov rdi,printf_debug_leftmost
    mov esi,dword[leftmost_point_i]
    mov edx,dword[leftmost_point_x]
    xor rax,rax
    call printf
	
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
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:

  ; Changer la couleur de dessin
	mov rdi,qword[display_name]
	mov rsi,qword[gc]
	mov edx,0x000000 ; black
	call XSetForeground

  ; draw evevry point
  xor rbx,rbx
  while_draw_points:
    cmp rbx,POINT_COUNT
    jge end_while_draw_points

    call draw_circle

    inc rbx
    jmp while_draw_points
  end_while_draw_points:


; ; Changer la couleur de dessin
; 	mov rdi,qword[display_name]
; 	mov rsi,qword[gc]
; 	mov edx,0x00FFFF	; Couleur du crayon
; 	call XSetForeground
; ; Fin Change la couleur de dessin
;
; 	mov dword[x1],200
; 	mov dword[y1],100
; ; Dessin d'un point	
; 	mov rdi,qword[display_name]
; 	mov rsi,qword[window]
; 	mov rdx,qword[gc]
; 	mov ecx,dword[x1]	; coordonnée en x
; 	mov r8d,dword[y1]	; coordonnée en y
; 	call XDrawPoint
; ; Fin Dessin d'un point

; Changer la couleur de dessin
	mov rdi,qword[display_name]
	mov rsi,qword[gc]
	mov edx,0xFF00FF	; Couleur du crayon (violet)
	call XSetForeground
; Fin Change la couleur de dessin

	mov dword[x1],100
	mov dword[y1],100
	mov dword[x2],200
	mov dword[y2],150
; Dessin d'une ligne
	mov rdi,qword[display_name]
	mov rsi,qword[window]
	mov rdx,qword[gc]
	mov ecx,dword[x1]	; coordonnée source en x
	mov r8d,dword[y1]	; coordonnée source en y
	mov r9d,dword[x2]	; coordonnée destination en x
	mov r14d,dword[y2]
	push r14		; coordonnée destination en y
	call XDrawLine
	add rsp,8
; Fin Dessin d'une ligne

; Changer la couleur de dessin
	mov rdi,qword[display_name]
	mov rsi,qword[gc]
	mov edx,0xFFFF00	; Couleur du crayon (jaune)
	call XSetForeground
; Fin Change la couleur de dessin

	mov dword[x1],200
	mov dword[y1],200
	mov dword[x2],50
	mov dword[y2],250
; Dessin d'une ligne
	mov rdi,qword[display_name]
	mov rsi,qword[window]
	mov rdx,qword[gc]
	mov ecx,dword[x1]	; coordonnée source en x
	mov r8d,dword[y1]	; coordonnée source en y
	mov r9d,dword[x2]	; coordonnée destination en x
	mov r14d,dword[y2]
	push r14		; coordonnée destination en y
	call XDrawLine
	add rsp,8
; Fin Dessin d'une ligne

; Changer la couleur de dessin
	mov rdi,qword[display_name]
	mov rsi,qword[gc]
	mov edx,0x00FFFF	; Couleur du crayon (cyan)
	call XSetForeground
; Fin Change la couleur de dessin

	mov dword[x1],250
	mov dword[y1],50
	mov dword[x2],150
	mov dword[y2],250
; Dessin d'une ligne
	mov rdi,qword[display_name]
	mov rsi,qword[window]
	mov rdx,qword[gc]
	mov ecx,dword[x1]	; coordonnée source en x
	mov r8d,dword[y1]	; coordonnée source en y
	mov r9d,dword[x2]	; coordonnée destination en x
	mov r14d,dword[y2]
	push r14		; coordonnée destination en y
	call XDrawLine
	add rsp,8
; Fin Dessin d'une ligne

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
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	
