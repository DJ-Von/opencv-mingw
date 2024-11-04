# Первый этап: Загрузка и распаковка OpenCV
FROM ubuntu:latest AS download

# Установка  wget  и  tar
RUN apt-get update && apt-get install -y \
    wget \
    tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/build

# Скачивание и распаковка OpenCV
RUN wget https://github.com/opencv/opencv/archive/refs/tags/4.10.0.tar.gz \
 && tar -xzvf 4.10.0.tar.gz 

# Второй этап: Сборка OpenCV
FROM ubuntu:latest AS build

# Установка cmake и других зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \ 
    git \
    wget \
    unzip \
    pkg-config \
    software-properties-common \
    ninja-build \
    # Установка зависимостей (zstd, GStreamer)
    zstd \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-good1.0-dev \
    # Устанавливаем MinGW-w64 здесь
    binutils-mingw-w64-x86-64 \
    g++-mingw-w64-x86-64 \
    gcc-mingw-w64-x86-64 \
    g++-multilib \ 
    && rm -rf /var/lib/apt/lists/*

# Настройка переменных окружения для MinGW-w64 (64-bit)
ENV CXX=x86_64-w64-mingw32-g++ 
ENV CC=x86_64-w64-mingw32-gcc
ENV PKG_CONFIG_PATH="/usr/x86_64-w64-mingw32/lib/pkgconfig"
ENV CMAKE_SYSTEM_NAME=Windows
ENV CMAKE_SYSTEM_PROCESSOR=x86_64

# Копируем распакованный OpenCV из первого этапа
COPY --from=download /opt/build/opencv-4.10.0 /opt/build/opencv-4.10.0

# Создание каталога сборк
RUN mkdir -p /opt/build/opencv-4.10.0/build_win64

# Копируем файл toolchain 
COPY toolchain-mingw64.cmake /opt/build/opencv-4.10.0/build_win64

# Переходим в каталог сборки
WORKDIR /opt/build/opencv-4.10.0/build_win64

# Запуск cmake, сборка, установка
RUN cmake -DCMAKE_TOOLCHAIN_FILE=toolchain-mingw64.cmake \
        -DCMAKE_INSTALL_PREFIX=/usr/local/opencv_win64 \ 
        -DBUILD_opencv_python3=ON \
        -DWITH_GSTREAMER=ON \
         ..
RUN cmake --build . --target install -- -j$(nproc)

# Настройка точки входа (опционально)
CMD ["/bin/bash"]