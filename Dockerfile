FROM debian:10 as builder
RUN apt update && apt dist-upgrade -y && apt install wget -y
WORKDIR /usr/src
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz && tar -zxvf asterisk-16-current.tar.gz --strip 1 && rm asterisk-16-current.tar.gz
ENV DEBIAN_FRONTEND noninteractive
RUN yes | ./contrib/scripts/install_prereq install
RUN ./contrib/scripts/get_mp3_source.sh
#RUN apt-get install -y 	build-essential git-core subversion libjansson-dev sqlite autoconf automake libxml2-dev libncurses5-dev libtool wget
RUN ./configure
RUN make menuselect.makeopts && ./menuselect/menuselect \
--enable format_mp3 \
--enable app_mp3 \
--enable res_srtp \
--enable res_crypto \
--enable CORE-SOUNDS-EN-WAV \
--enable CORE-SOUNDS-EN-ALAW \
--enable CORE-SOUNDS-EN-ULAW \
--enable CORE-SOUNDS-EN-GSM \
--enable CORE-SOUNDS-RU-WAV \
--enable CORE-SOUNDS-RU-ALAW \
--enable CORE-SOUNDS-RU-ULAW \
--enable CORE-SOUNDS-RU-GSM \
menuselect.makeopts

# Do not include sound files. You should be mounting these from and external
# volume.
#sed -i -e 's/MENUSELECT_MOH=.*$/MENUSELECT_MOH=/' menuselect.makeopts
#sed -i -e 's/MENUSELECT_CORE_SOUNDS=.*$/MENUSELECT_CORE_SOUNDS=/' menuselect.makeopts

# Build it!
RUN make all install DESTDIR=/asterisk -j4
RUN make samples DESTDIR=/asterisk


FROM debian:10
RUN apt update && apt dist-upgrade -y

RUN apt install libxml2 libxslt1.1 libsqlite3-0 libssl1.1 libjansson4 liburiparser1 libedit2 libjack-jackd2-0 libosptk4 libodbc1 libpq5 libradcli4 libsybdb5 libiksemel3 libcodec2-0.8.1 libgsm1 libspeex1 libvorbis0a libcurl4 libresample1 libspeexdsp1 libvorbisenc2 libspeexdsp1 liblua5.2-0 libneon27 libspandsp2 libgmime-2.6-0 libunbound8 libsnmp30 libsrtp2-1 libvorbisfile3 libical3 -y

COPY --from=builder /asterisk /
RUN useradd -m asterisk  
RUN chown asterisk. /var/run/asterisk && \
chown -R asterisk. /etc/asterisk && \
chown -R asterisk. /var/lib/asterisk && \
chown -R asterisk. /var/log/asterisk && \
chown -R asterisk. /var/spool/asterisk && \
chown -R asterisk. /usr/lib/asterisk
USER asterisk
#VOLUME /etc/asterisk/
#ENTRYPOINT /usr/sbin/asterisk
CMD asterisk -fvvvvvvvvvvvvvv
