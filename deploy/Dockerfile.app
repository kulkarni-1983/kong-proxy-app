FROM python:alpine

ARG ARG_APP_PORT

ENV SERVER_PORT $ARG_APP_PORT
EXPOSE $SERVER_PORT

RUN mkdir /opt/app
RUN pip3 install --upgrade pip && \
    pip3 install flask

COPY ./test-application/* /opt/app

WORKDIR /opt/app
CMD python ./flask-application.py