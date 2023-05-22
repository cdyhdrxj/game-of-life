#!/usr/bin/env bash


# Проверяет размеры терминала
function check_term() {
    # Не менее 5x5 + справка должна умещаться на одну строку
    MIN_COL=5
    MIN_LINE=5

    if [[ $MIN_COL -lt ${#HELP} ]] ; then
        MIN_COL=${#HELP}
    fi

    if [[ ${1} -lt $MIN_COL ]] || [[ ${2} -lt $MIN_LINE ]] ; then
        echo "Please resize your terminal to at least ${MIN_COL}x${MIN_LINE}"
        exit 1
    fi
}


# Возвращает настройки терминала и выходит из приложения
function quit() {
    clear
    tput cnorm
    stty echo
    exit 0
}


# Печатает строку {3} на позицию с координатами {1} {2}
# (нумерация строк/столбцов с 1)
function printxy () { printf "\033[${1};${2}f${3}" ; }


# Формирует следующее поколение клеток в массиве cell
function next_generation(){
    # Считаем, что поле замкнуто: верхняя граница поля соединена с нижней, 
    #                             левая - с правой

    # Для каждой клетки поля считаем количество живых соседей neighbors
    #                                           и заполняем массив temp
    declare -A temp
    for (( i=0 ; i<LINE ; i++ )) ; do
        for (( j=0 ; j<COL ; j++ )) ; do
            neighbors=0

            a=$(( (LINE+$i-1)%LINE )) ; b=$(( (COL+$j-1)%COL ))
            ((neighbors+=${cell[$a,$b]}))
            
            a=$(( (LINE+$i-1)%LINE )) ; b=$j
            ((neighbors+=${cell[$a,$b]}))
            
            a=$(( (LINE+$i-1)%LINE )) ; b=$(( (COL+$j+1)%COL ))
            ((neighbors+=${cell[$a,$b]}))
            
            a=$i                      ; b=$(( (COL+$j-1)%COL ))
            ((neighbors+=${cell[$a,$b]}))
            
            a=$i                      ; b=$(( (COL+$j+1)%COL ))
            ((neighbors+=${cell[$a,$b]}))
            
            a=$(( (LINE+$i+1)%LINE )) ; b=$(( (COL+$j-1)%COL ))
            ((neighbors+=${cell[$a,$b]}))
            
            a=$(( (LINE+$i+1)%LINE )) ; b=$j
            ((neighbors+=${cell[$a,$b]}))
            
            a=$(( (LINE+$i+1)%LINE )) ; b=$(( (COL+$j+1)%COL ))
            ((neighbors+=${cell[$a,$b]}))

            if [[ $neighbors -gt 3 ]] || [[ $neighbors -lt 2 ]] ; then
                temp[$i,$j]=0
            elif [[ $neighbors -eq 3 ]] ; then
                temp[$i,$j]=1
            else
                temp[$i,$j]=${cell[$i,$j]}
            fi
        done
    done 

    # Обновляем cell
    for (( i=0 ; i<LINE ; i++ )) ; do
        for (( j=0 ; j<COL ; j++ )) ; do
            cell[$i,$j]=${temp[$i,$j]}
        done
    done
}

# Название игры и справка
LABEL="GAME OF LIFE"
HELP="hjkl - navigate    c - place/remove cell    s - start game   q - quit"

# Проверяем размеры терминала
TERM_COL=$(tput cols)
TERM_LINE=$(tput lines)
check_term "$TERM_COL" "$TERM_LINE"

# Размеры поля
COL=$(( $TERM_COL-4 ))
LINE=$(( $TERM_LINE-4 ))

# Координаты верхнего левого угла поля
X_BEGIN=2
Y_BEGIN=2

# Ассоциативный массив клеток (cell[i,j] = 1, если клетка живая, 0 - иначе,
#                                             i, j - координаты клетки в поле)
declare -A cell

for (( i=0 ; i<LINE ; i++ )) ; do
    for (( j=0 ; j<COL ; j++ )) ; do
        cell[$i,$j]=0
    done
done

# На выходе возвращаем настройки терминала
trap quit INT TERM SIGINT SIGTERM EXIT
clear 

# Скрываем ввод
stty -echo

# Печатаем название игры, справку и границы поля
printxy 1 $((($COL-${#LABEL}/2)/2)) "$LABEL"
printxy $(($X_BEGIN+$LINE+2)) $Y_BEGIN "$HELP"

for (( i=0 ; i<COL+2 ; i++ )) ; do
    printxy $X_BEGIN $(($Y_BEGIN+i)) "═"
    printxy $(($X_BEGIN+$LINE+1)) $(($Y_BEGIN+i)) "═"
done

for (( i=0 ; i<LINE+2 ; i++ )) ; do
    printxy $(($X_BEGIN+i)) $Y_BEGIN "║"
    printxy $(($X_BEGIN+i)) $(($Y_BEGIN+$COL+1)) "║"
done

printxy $X_BEGIN              $Y_BEGIN             "╔"
printxy $(($X_BEGIN+$LINE+1)) $Y_BEGIN             "╚"
printxy $X_BEGIN              $(($Y_BEGIN+$COL+1)) "╗"
printxy $(($X_BEGIN+$LINE+1)) $(($Y_BEGIN+$COL+1)) "╝"

# Координаты текущей клетки в поле (нумерация строк/столбцов с 0)
X=0
Y=0

printxy $(($X_BEGIN+1)) $(($Y_BEGIN+1)) ""

# Цикл расстановки клеток на поле
# (hjkl - управление курсором, c - поставить/убрать клетку, s - начать игру, q - выйти)
while true ; do
    read -t0.5 -n1 input
    
    case $input in
        "h") ((Y--)); [[ $Y -lt 0 ]] && Y=0 ;;
        "j") ((X++)); [[ $X -ge $LINE ]] && X=$(($LINE-1)) ;;
        "k") ((X--)); [[ $X -lt 0 ]] && X=0 ;;
        "l") ((Y++)); [[ $Y -ge $COL ]] && Y=$(($COL-1))  ;;
        "c") if [[ ${cell[$X,$Y]} -eq 0 ]] ; then
                 cell[$X,$Y]=1
                 printxy $(($X+$X_BEGIN+1)) $(($Y+$Y_BEGIN+1)) "●"
             else
                 cell[$X,$Y]=0
                 printxy $(($X+$X_BEGIN+1)) $(($Y+$Y_BEGIN+1)) " "
             fi ;;
        "s") break ;;
        "q") quit ;;
    esac
    # Перемещаем курсор
    printxy $(($X+$X_BEGIN+1)) $(($Y+$Y_BEGIN+1)) ""
done

# Обновляем справку
HELP="q - quit"
printxy $(($X_BEGIN+$LINE+2)) $Y_BEGIN "\033[K$HELP"

# Отключаем курсор
tput civis

period=0.5
# Каждые period секунд формируем новое поколение и обновляем экран
# (при большом разрешении окна терминала время обновления может быть большe,
# т.к. требуется больше времени на заполнение массива cell)
while true ; do
    read -t${period} -n1 input

    # Выходим при нажатии q
    if [[ $input == "q" ]] ; then
        quit
    fi

    next_generation
   
    for (( i=0 ; i<LINE ; i++ )) ; do
        for (( j=0 ; j<COL ; j++ )) ; do

            if [[ ${cell[$i,$j]} -eq 0 ]] ; then
                 printxy $(($i+$X_BEGIN+1)) $(($j+$Y_BEGIN+1)) " "
             else
                 printxy $(($i+$X_BEGIN+1)) $(($j+$Y_BEGIN+1)) "●"
             fi  

        done
    done
done
