FROM python:alpine

ENV SERVER_PORT 8080
EXPOSE $SERVER_PORT

RUN mkdir /opt/app
RUN pip3 install --upgrade pip && \
    pip3 install flask

COPY ./test-application/* /opt/app

WORKDIR /opt/app
CMD python ./flask-application.py